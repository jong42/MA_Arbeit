ALTER TABLE model_draft.ego_grid_lv_loadareaaoi
ADD COLUMN real_ons_nr integer;

UPDATE model_draft.ego_grid_lv_loadareaaoi AS t1
SET real_ons_nr = 0;

UPDATE model_draft.ego_grid_lv_loadareaaoi AS t1
SET real_ons_nr = ons_nr FROM
	(SELECT area.id AS area_id, COUNT(pts.geom) AS ons_nr
	FROM model_draft.ego_grid_lv_loadareaaoi AS area, model_draft.ego_grid_mvlv_referenceontpoints AS pts
	WHERE ST_INTERSECTS (area.geom,pts.geom)
	GROUP BY area.id) AS t2
	WHERE t1.id = t2.area_id;

ALTER TABLE model_draft.ego_grid_lv_loadareaaoi
ADD COLUMN modelled_ons_nr integer;

UPDATE model_draft.ego_grid_lv_loadareaaoi AS t1
SET modelled_ons_nr = 0;

UPDATE model_draft.ego_grid_lv_loadareaaoi AS t1
SET modelled_ons_nr = ons_nr FROM
	(SELECT area.id AS area_id, COUNT(pts.geom) AS ons_nr
	FROM model_draft.ego_grid_lv_loadareaaoi AS area, model_draft.ego_grid_mvlv_ontcontrolgroup AS pts
	WHERE ST_INTERSECTS (area.geom,pts.geom)
	GROUP BY area.id) AS t2
	WHERE t1.id = t2.area_id;