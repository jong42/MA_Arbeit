DROP TABLE model_draft.ego_grid_lv_candidatpoints

-- Create initial table

CREATE TABLE model_draft.ego_grid_lv_candidatpoints AS

SELECT DISTINCT t1.geom::geometry(POINT,3035) FROM


	(SELECT ST_STARTPOINT (geom) AS geom
	FROM model_draft.ego_grid_lv_streetsaoi

	UNION

	SELECT ST_ENDPOINT (geom) AS geom
	FROM model_draft.ego_grid_lv_streetsaoi) AS t1;


 ALTER TABLE model_draft.ego_grid_lv_candidatpoints ADD COLUMN id SERIAL PRIMARY KEY;

ALTER TABLE model_draft.ego_grid_lv_zensusaoi
ADD COLUMN la_id integer;

UPDATE model_draft.ego_grid_lv_zensusaoi AS a
SET la_id = b.second_id
FROM model_draft.ego_grid_lv_loadareaaoi AS b
WHERE ST_INTERSECTS (a.geom,b.geom);

ALTER TABLE model_draft.ego_grid_lv_streetsaoi
ADD COLUMN la_id integer;

UPDATE model_draft.ego_grid_lv_streetsaoi AS a
SET la_id = b.second_id
FROM model_draft.ego_grid_lv_loadareaaoi AS b
WHERE ST_INTERSECTS (a.geom,b.geom);



-- Füge Attribut pop50 hinzu (Bevölkerung im Umkreis von 50m)
ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN pop50 integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS onts
SET pop50 = 0;

UPDATE model_draft.ego_grid_lv_candidatpoints AS onts
SET pop50 =     t1.pop50
FROM (		SELECT pts.id,SUM (pop.population) AS pop50
		FROM model_draft.ego_grid_lv_zensusaoi AS pop, model_draft.ego_grid_lv_candidatpoints AS pts
		WHERE ST_CONTAINS(ST_BUFFER(pts.geom,50),pop.geom) AND ST_BUFFER(pts.geom,50) && pop.geom AND pop.population > 0 AND pop.la_id = pts.la_id
		GROUP BY pts.id)t1
WHERE onts.id = t1.id
;
-- Füge Attribut pop100 hinzu (Bevölkerung im Umkreis von 100m)		
ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN pop100 integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS onts
SET pop100 = 0;

UPDATE model_draft.ego_grid_lv_candidatpoints AS onts
SET pop100 =     t1.pop100
FROM (		SELECT pts.id,SUM (pop.population) AS pop100
		FROM model_draft.ego_grid_lv_zensusaoi AS pop, model_draft.ego_grid_lv_candidatpoints AS pts
		WHERE ST_CONTAINS(ST_BUFFER(pts.geom,100),pop.geom) AND ST_BUFFER(pts.geom,100) && pop.geom AND pop.population > 0 AND pop.la_id = pts.la_id
		GROUP BY pts.id)t1
WHERE onts.id = t1.id;

-- Füge Attribut diststreet hinzu (Entfernung zur nächsten Straße)

ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN diststreet integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET diststreet = distance 
FROM
	(SELECT t1.id, MIN(ST_DISTANCE(t2.geom,t1.geom)) AS distance
	FROM model_draft.ego_grid_lv_candidatpoints AS t1,model_draft.ego_grid_lv_streetsaoi AS t2
	WHERE ST_EXPAND(t1.geom,200) && t2.geom
	GROUP BY t1.id)AS s2
WHERE s2.id = s1.id;

--
-- Füge Attribut distcrossroad hinzu (Entfernung zur nächsten Straßenkreuzung)


ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN distcrossroad integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET distcrossroad = distance 
FROM
	(SELECT t1.id, MIN(ST_DISTANCE(ST_TRANSFORM(t2.geom,3035),t1.geom)) AS distance
	FROM model_draft.ego_grid_lv_candidatpoints AS t1,model_draft.ego_osm_deu_street_streetcrossing AS t2
	WHERE ST_EXPAND(t1.geom,200) && ST_TRANSFORM(t2.geom,3035)
	GROUP BY t1.id)AS s2
WHERE s2.id = s1.id;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET distcrossroad = s2.dist
FROM (SELECT AVG (distcrossroad) AS dist FROM model_draft.ego_grid_lv_candidatpoints) AS s2
WHERE s1.distcrossroad IS NULL;

ALTER TABLE model_draft.ego_grid_lv_buildingsaoi
ADD COLUMN la_id integer;

UPDATE model_draft.ego_grid_lv_buildingsaoi AS a
SET la_id = b.id
FROM model_draft.ego_grid_lv_loadareaaoi AS b
WHERE ST_CONTAINS (b.geom,ST_TRANSFORM(a.geom,3035));

 -- Füge Attribut buildungsnr50 hinzu (Anzahl an Gebäuden im Umkreis von 50m)

ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN buildingsnr50 integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsnr50 = 0;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsnr50 = buildungsnr
FROM
	(SELECT t1.id, COUNT(t2.geom) AS buildungsnr
	FROM model_draft.ego_grid_lv_candidatpoints AS t1,model_draft.ego_grid_lv_buildingsaoi AS t2
	WHERE ST_INTERSECTS(ST_TRANSFORM(t2.geom,3035),ST_BUFFER(t1.geom,50)) AND ST_BUFFER(t1.geom,50) && ST_TRANSFORM(t2.geom,3035) AND t2.la_id = t1.la_id
	GROUP BY t1.id)AS s2
WHERE s2.id = s1.id;

-- Füge Attribut buildingsarea100 hinzu (Summe der Gebäudefläche im Umkreis von 100m)
ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN buildingsarea100 integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsarea100 = 0;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsarea100 = buildingsarea
FROM
	(SELECT t1.id, SUM(ST_AREA(ST_TRANSFORM(t2.geom,3035))) AS buildingsarea
	FROM model_draft.ego_grid_lv_candidatpoints AS t1,model_draft.ego_grid_lv_buildingsaoi AS t2
	WHERE ST_INTERSECTS(ST_TRANSFORM(t2.geom,3035),ST_BUFFER(t1.geom,100)) AND ST_BUFFER(t1.geom,100) && ST_TRANSFORM(t2.geom,3035) AND t2.la_id = t1.la_id
	GROUP BY t1.id)AS s2
WHERE s2.id = s1.id;

-- Füge Attribut buildingsarea250 hinzu (Summe der Gebäudefläche im Umkreis von 250m)
ALTER TABLE model_draft.ego_grid_lv_candidatpoints
ADD COLUMN buildingsarea250 integer;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsarea250 = 0;

UPDATE model_draft.ego_grid_lv_candidatpoints AS s1
SET buildingsarea250 = buildingsarea
FROM
	(SELECT t1.id, SUM(ST_AREA(ST_TRANSFORM(t2.geom,3035))) AS buildingsarea
	FROM model_draft.ego_grid_lv_candidatpoints AS t1,model_draft.ego_grid_lv_buildingsaoi AS t2
	WHERE ST_INTERSECTS(ST_TRANSFORM(t2.geom,3035),ST_BUFFER(t1.geom,250)) AND ST_BUFFER(t1.geom,250) && ST_TRANSFORM(t2.geom,3035) AND t2.la_id = t1.la_id
	GROUP BY t1.id)AS s2
WHERE s2.id = s1.id;