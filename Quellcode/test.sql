-- (141 msec)

CREATE OR REPLACE FUNCTION ST_CreateFishnet(
        nrow integer, ncol integer,
        xsize float8, ysize float8,
        x0 float8 DEFAULT 0, y0 float8 DEFAULT 0,
        
        OUT geom geometry)
    RETURNS SETOF geometry AS
$$
SELECT ST_Translate(cell, j * $3 + $5, i * $4 + $6) AS geom
FROM generate_series(0, $1 - 1) AS i,
     generate_series(0, $2 - 1) AS j,
(
SELECT ('POLYGON((0 0, 0 '||$4||', '||$3||' '||$4||', '||$3||' 0,0 0))')::geometry AS cell
) AS foo;
$$ LANGUAGE sql IMMUTABLE STRICT;

TRUNCATE TABLE  calc_ego_grid_district."test_ego_deu_ontgrids";
INSERT INTO calc_ego_grid_district."test_ego_deu_ontgrids" (geom, load_area_id)

-- Erstelle ein Gitternetz auf der bbox der Lastgebiete:

	
	SELECT 
	-- Normalfall: mehrere Zellen pro Grid
	CASE WHEN ST_AREA (geom) > (3.1415926535 * 1152) THEN

	ST_SETSRID(ST_CREATEFISHNET(
		ROUND((ST_ymax(box2d(geom)) -  ST_ymin(box2d(geom))) /319)::integer,
		ROUND((ST_xmax(box2d(geom)) -  ST_xmin(box2d(geom))) /319)::integer,
		319,
		319,
		ST_xmin (box2d(geom)),
		ST_ymin (box2d(geom))
	),3035)::geometry(POLYGON,3035)  


	-- Spezialfall: bei kleinene Lastgebieten erstelle nur eine Zelle
	ELSE
	
	ST_SETSRID(ST_CREATEFISHNET(
		1,
		1,
		(ST_ymax(box2d(geom)) -  ST_ymin(box2d(geom))),
		(ST_xmax(box2d(geom)) -  ST_xmin(box2d(geom))),
		ST_xmin (box2d(geom)),
		ST_ymin (box2d(geom))
	),3035)::geometry(POLYGON,3035) 

	END AS geom, area.id AS load_area_id

FROM calc_ego_loads."ego_deu_load_area" AS area 
WHERE area.id >= 121296 AND area.id <= 121320 ;



  
TRUNCATE TABLE calc_ego_substation."test_ego_deu_onts";
INSERT INTO calc_ego_substation."test_ego_deu_onts" (geom, load_area_id)

-- Bestimme diejenigen Mittelpunkte der Grid-Polygone, die innerhalb der Lastgebiete liegen:
SELECT DISTINCT ST_CENTROID (grids.geom)::geometry(POINT,3035) AS geom, area.id AS load_area_id
FROM calc_ego_grid_district."test_ego_deu_ontgrids" AS grids, calc_ego_loads."ego_deu_load_area" AS area
WHERE ST_WITHIN(ST_CENTROID (grids.geom),area.geom)
	AND area.id = grids.load_area_id;

-- Füge den Lastgebieten, die aufgrund ihrer geringen Fläche keine ONTs zugeordnet bekommen haben, ihren Mittelpunkt als ONT-STandort hinzu: (01:54 min)
--INSERT INTO calc_ego_substation."test_ego_deu_onts" (geom, load_area_id)

--SELECT
--CASE WHEN ST_CONTAINS (geom,ST_CENTROID(area_without_ont.geom)) THEN 

--ST_CENTROID(area_without_ont.geom)

--ELSE

--ST_POINTONSURFACE(area_without_ont.geom)

--END, area_without_ont.id 

--FROM

--	(SELECT geom, id
--	FROM calc_ego_loads."ego_deu_load_area" 
--	EXCEPT
--	SELECT l_area.geom AS geom, l_area.id
--	FROM calc_ego_loads."ego_deu_load_area" AS l_area, calc_ego_substation."test_ego_deu_onts" AS ont
--	WHERE ST_CONTAINS (l_area.geom, ont.geom) 
--	GROUP BY (l_area.id)) 
--	AS area_without_ont
--;

	
-- Lege Buffer um ONT-STandorte und ermittle die Teile der Lastgebiete, die sich nicht innerhalb dieser Buffer befinden
TRUNCATE TABLE calc_ego_grid_district."test_ego_deu_load_area_rest";
INSERT INTO calc_ego_grid_district."test_ego_deu_load_area_rest" (geom, load_area_id)

SELECT (ST_DUMP(ST_DIFFERENCE(load_area.geom, area_with_onts.geom))).geom::geometry(Polygon,3035) AS geom, load_area.id AS load_area_id

FROM
	(SELECT ST_BUFFER(ST_UNION(onts.geom),576) AS geom,l_area.id AS id
	FROM calc_ego_substation."test_ego_deu_onts" AS onts, calc_ego_loads."ego_deu_load_area" AS l_area 
	WHERE ST_CONTAINS (l_area.geom,onts.geom) AND (l_area.geom && onts.geom)
	GROUP BY l_area.id) AS area_with_onts 

	INNER JOIN

	calc_ego_loads."ego_deu_load_area" AS load_area 

	ON (load_area.id = area_with_onts.id ) 

WHERE  ST_AREA(ST_DIFFERENCE(load_area.geom, area_with_onts.geom)) > 0
	AND load_area.id >= 121296 AND load_area.id <= 121320
;


  
-- Bestimme die Mittelpunkte der Gebiete, die noch nicht durch ONT abgedeckt sind, und lege diese Mittelpunkte als ONT-Standorte fest
INSERT INTO calc_ego_substation."test_ego_deu_onts" (geom, load_area_id)
SELECT ST_CENTROID(geom)::geometry(POINT,3035), load_area_id FROM calc_ego_grid_district."test_ego_deu_load_area_rest"
;


-- Setze dummy-flag auf false für alle erzeugten ONTs
UPDATE calc_ego_substation."test_ego_deu_onts" 
SET is_dummy = FALSE;

-- Füge Information für die substation_id hinzu

UPDATE 	calc_ego_substation.test_ego_deu_onts AS t1
SET  	subst_id = t2.subst_id
FROM    (
	SELECT	ont.id AS id,
		gd.subst_id AS subst_id
	FROM	calc_ego_substation.test_ego_deu_onts AS ont,
		calc_ego_grid_district.grid_district AS gd
	WHERE  	gd.geom && ont.geom AND
		ST_CONTAINS(gd.geom,ont.geom)
	) AS t2
WHERE  	t1.id = t2.id;


-- Set comment on table
COMMENT ON TABLE calc_ego_substation.test_ego_deu_onts IS
'{
"Name": "eGo data processing - test_ego_deu_onts",
"Source": [{
                  "Name": "open_eGo",
                  "URL":  "https://github.com/openego/data_processing" }],
"Reference date": "2016",
"Date of collection": "2016-10-12",
"Original file": "test_ego_deu_onts.sql",
"Spatial resolution": ["small test area"],
"Description": ["eGo data processing modeling of ONTs"],

"Column": [
                {"Name": "id",
                "Description": "Unique identifier",
                "Unit": "" },
				
				{"Name": "geom",
                "Description": "Geometry",
                "Unit": "" },
				
				{"Name": "load_area_id",
                "Description": "ID of the corresponding load area",
                "Unit": "" },
				
				{"Name": "subst_id",
                "Description": "ID of the corresponding MV substation",
                "Unit": "" },

                				{"Name": "is_dummy",
                "Description": "True if the entry is a dummy entry",
                "Unit": "" }],

"Changes":[
                {"Name": "Jonas Gütter",
                "Mail": "jonas.guetter@rl-institut.de",
                "Date":  "12.10.2016",
                "Comment": "Created table" }],

"ToDo": [""],
"Licence": ["tba"],
"Instructions for proper use": [""]
}'; 

-- Select description
SELECT obj_description('calc_ego_substation.test_ego_deu_onts'::regclass)::json;
