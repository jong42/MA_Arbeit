DROP TABLE IF EXISTS model_draft.ego_grid_lv_streets;

CREATE TABLE model_draft.ego_grid_lv_streets

AS

SELECT osm.gid AS line_gid,ST_Safe_Intersection (ST_TRANSFORM(osm.geom,3035), larea.geom)::geometry(LineString,3035) AS geom, larea.id AS load_area_id , numbers.ontnumber AS ontnumber
		FROM openstreetmap.osm_deu_line AS osm, 
		     calc_ego_loads.ego_deu_load_area AS larea,
		     (SELECT COUNT(pts.geom) AS ontnumber,area.id AS load_area_id FROM calc_ego_substation.ego_deu_onts AS pts,calc_ego_loads.ego_deu_load_area AS area
				WHERE ST_INTERSECTS (pts.geom,area.geom) 
				GROUP BY area.id
		     )AS numbers 
		WHERE (osm."highway" = 'motorway' OR osm."highway" = 'trunk' OR osm."highway" = 'primary' OR osm."highway" = 'secondary' OR  osm."highway" = 'tertiary' OR  osm."highway" = 'unclassified' OR osm."highway" = 'residential' OR osm."highway" = 'service' OR osm."highway" = 'living_street' 
		OR  osm."highway" = 'pedestrian' OR osm."highway" = 'bus_guideway' OR osm."highway" = 'road' OR osm."highway" = 'footway')
		AND numbers.load_area_id = larea.id
		AND  ST_INTERSECTS(ST_TRANSFORM(osm.geom,3035),larea.geom)
		AND ST_GEOMETRYTYPE (ST_Safe_Intersection (ST_TRANSFORM(osm.geom,3035),larea.geom)) = 'ST_LineString'
			 
;

ALTER TABLE model_draft.ego_grid_lv_streets
  OWNER TO oeuser;
GRANT ALL ON TABLE model_draft.ego_grid_lv_streets TO oeuser WITH GRANT OPTION;


CREATE INDEX ego_grid_lv_streets_geom_idx
  ON model_draft.ego_grid_lv_streets
  USING gist
  (geom);

-- Create ID column
ALTER TABLE model_draft.ego_grid_lv_streets
ADD COLUMN id serial;

ALTER TABLE model_draft.ego_grid_lv_streets
ADD CONSTRAINT ego_grid_lv_streets_pkey PRIMARY KEY (id);

--
CREATE UNIQUE INDEX   ego_grid_lv_streets_id_idx
        ON    model_draft.ego_grid_lv_streets (id);


