-- Table: info_statistics_company

-- DROP TABLE info_statistics_company;

CREATE TABLE info_statistics_company
(
  account_id integer NOT NULL,
  battles integer,
  wins integer,
  losses integer,
  draws integer,
  survived_battles integer,
  tanking_factor numeric,
  base_xp integer,
  xp integer,
  battle_avg_xp integer,
  avg_damage_blocked numeric,
  avg_damage_assisted numeric,
  avg_damage_assisted_track numeric,
  avg_damage_assisted_radio numeric,
  hits_percents integer,
  frags integer,
  spotted integer,
  capture_points integer,
  dropped_capture_points integer,
  shots integer,
  hits integer,
  piercings integer,
  explosion_hits integer,
  no_damage_direct_hits_received integer,
  damage_dealt integer,
  damage_received integer,
  direct_hits_received integer,
  piercings_received integer,
  explosion_hits_received integer,
  CONSTRAINT info_statistics_company_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE info_statistics_company
  OWNER TO wotstatsadmins;
