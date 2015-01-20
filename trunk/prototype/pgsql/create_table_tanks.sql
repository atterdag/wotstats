-- Table: tanks

-- DROP TABLE tanks;

CREATE TABLE tanks
(
  tank_id integer NOT NULL,
  nation_i18n character(12),
  name character(64),
  image character(256),
  image_small character(256),
  nation character(12),
  is_premium boolean,
  type_i18n character(16),
  contour_image character(256),
  short_name_i18n character(32),
  name_i18n character(32),
  type character(16),
  CONSTRAINT tanks_global_pkey PRIMARY KEY (tank_id)
)
WITH (
  OIDS=FALSE,
  autovacuum_enabled=true
);
ALTER TABLE tanks
  OWNER TO wotstatsadmins;
