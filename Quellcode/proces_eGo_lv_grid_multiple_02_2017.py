"""
Create LV lines and substations
"""


import networkx as nx
from sqlalchemy import create_engine
from sqlalchemy.sql import text
from oemof import db
from shapely.wkt import loads
import math
import time

t0 = time.clock()


# connect to database
engine = create_engine('postgresql://postgres:chilli@localhost:5432/MA_Arbeit')
conn = engine.connect()


s = text("SELECT COUNT(id) AS numberofloadareas FROM model_draft.ego_grid_lv_loadareaaoi")
result = conn.execute(s)
for row in result:
    numberofloadareas = row['numberofloadareas']
result.close()

# Iterate over load areas
for w in range(1,numberofloadareas):

    # Initialize variables
    onts = []
    distmax = 250
    xcoord = []
    ycoord = []
    dominated = []
    ont = []
    street_geoms = []
    street_gids = []

    print ('new iteration step begins  ', (time.clock() - t0, "seconds process time"))

    # Create graph
    graph = nx.Graph()
    s = text(
			"SELECT ST_X(geom) AS X, ST_Y(geom) AS Y, pop50,pop100,diststreet,distcrossroad,buildingsnr50,buildingsarea100,buildingsarea250 FROM model_draft.ego_grid_lv_candidatpoints WHERE la_id = :x")
    result = conn.execute(s, x = w)
    print ("load_area_id:",w)
    for row in result:
		# Get attributes from SQL result

        pop50 = row['pop50']
        pop100 = row['pop100']
        diststreet = row['diststreet']
        distcrossroad = row['distcrossroad']
        buildingsnr50 = row['buildingsnr50']
        buildingsarea100 = row['buildingsarea100']
        buildingsarea250 = row['buildingsarea250']

    	name = (row['x'],row['y'])


		# Add node and corresponding attributes to graph
        graph.add_node(name, pop50=pop50,pop100=pop100,diststreet=diststreet,
			distcrossroad=distcrossroad,buildingsnr50=buildingsnr50,
			buildingsarea100=buildingsarea100,buildingsarea250=buildingsarea250,)

    result.close()
    s = text(
            "SELECT ST_AsText(ST_UNION(ST_MULTI(geom))) AS geom, ST_GEOMETRYTYPE(ST_UNION(ST_MULTI(geom))) AS type, \
            AVG(ontnumber) AS ontnumber FROM model_draft.ego_grid_lv_streetsaoi WHERE la_id = :x")
    result = conn.execute(s, x = w)

#    print("type:"+str(type(result)))
    # Get number of ont for this load area
    for row in result:
        #print("row:"+str(row))
        numberofonts = row['ontnumber']
        result2 = row['geom']
        resulttype = row['type']

    # Do nothing if there is no or only one street in the load area:
    if (str(result2) == "None"):
        print ("passed")
        pass
    elif (resulttype == "ST_LineString"):
        print('only one street in the load area')
    else:

        #print ("result2:" + str(result2))
        wkt = loads(result2)

        print ('number of nodes:')
        print (graph.number_of_nodes())

        for line in wkt:
            for seg_start, seg_end in zip(list(line.coords),list(line.coords)[1:]):
                graph.add_edge(seg_start, seg_end,)

        result.close()

        print ('number of nodes:')
        print (graph.number_of_nodes())

        print ('change to undirected graph  ', (time.clock() - t0, "seconds process time"))
        # change to undirected graph
        graph = graph.to_undirected()

        # Leave out very big load_areas due to performance issues
        if(graph.number_of_nodes() > 9000):
            print ("Street network is too large")
        else:
            # Perform positioning algorithm on graph
            # Step 1: Mark every node as undominated
            print ('Step 1  ', (time.clock() - t0, "seconds process time"))
            for x in range(0, graph.number_of_nodes()):
                graph.node[graph.nodes()[x]]['dominated'] = None
                graph.node[graph.nodes()[x]]['ONT'] = False

            # Step 2 (has to be updated)
            print ('Step 2.1  ', (time.clock() - t0, "seconds process time"))
            # Step 2.1: Calculate the probability that there is an ONS for each node:
            for x in range(0, graph.number_of_nodes()):
               graph.node[graph.nodes()[x]]['prob'] = -9999
               if ('pop50' in graph.node[graph.nodes()[x]]):

              	    prob = 0.005662* graph.node[graph.nodes()[x]]['pop50'] - 0.001099* graph.node[graph.nodes()[x]]['pop100'] \
                    	- 0.003498* graph.node[graph.nodes()[x]]['diststreet'] - 0.00353* graph.node[graph.nodes()[x]]['distcrossroad']\
                    	+ 0.00348* graph.node[graph.nodes()[x]]['buildingsnr50'] + 0.0000325* graph.node[graph.nodes()[x]]['buildingsarea100']\
                    	+ 0.000008963* graph.node[graph.nodes()[x]]['buildingsarea250']
                    graph.node[graph.nodes()[x]]['prob'] = prob


            # Step 2.2: Calculate the length of each edge
            print ('Step 2.2  ', (time.clock() - t0, "seconds process time"))
            for x in range(0, graph.number_of_edges()):
                first = graph.edges(data=True)[x]
                distance = math.sqrt(sum([(a - b) ** 2 for a, b in zip(first[0],first[1])]))
                graph.edge[first[0]][first[1]]['weight'] = distance
            #print ('nodes:')
            #print (graph.nodes(data=True))

            print ('Step 2.3  ', (time.clock() - t0, "seconds process time"))
            for x in range(0, int(numberofonts)):
                # Step 2.3: Add the node with the most adjacent undominated nodes to onts
                max_prob = max(nx.get_node_attributes(graph, 'prob').values())
                #print('max neighbors:' + str(max_neighbors))
                for y in range (0, graph.number_of_nodes()):

                    if (graph.node[graph.nodes()[y]]['prob'] == max_prob):
                        nextont = graph.nodes()[y]
                        graph.node[graph.nodes()[y]]['ONT'] = True
                        onts.append (nextont)
                        break


                # Step 3: Mark every node within the range of the previously added ont as dominated

                # Step 3.1: Calculate the distance for each node and the previously added ont
                distances = nx.single_source_dijkstra_path_length (graph, source =
                   nextont, cutoff=distmax, weight= 'weight')


                # Step 3.2: Mark every node within the range as zero probability for ONS
                #print ('distances:')
                #print (distances)
                for y in distances.keys():
                    graph.node[y]['prob'] = 0


        # create output graph
        out_graph = graph.copy()
        out_graph.remove_nodes_from(graph.nodes())
        out_graph.add_nodes_from(onts)


        # Insert values into table
        s = text(
                "Insert into model_draft.ego_grid_lv_ons (geom) SELECT ST_SetSRID(ST_MAKEPOINT(:x,:y),3035)")

        for z in range(0, out_graph.number_of_nodes()):
            #print (out_graph.nodes()[z][0])
            result = conn.execute(s, x = out_graph.nodes()[z][0],y = out_graph.nodes()[z][1])

        result.close()

# Close db connection
conn.close()

print ((time.clock() - t0)/3600, "hours process time")



