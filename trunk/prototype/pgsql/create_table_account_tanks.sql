-- Table: account_tanks

-- DROP TABLE account_tanks;

CREATE TABLE account_tanks
(
  account_id integer NOT NULL,
  tank_id integer NOT NULL,
  mark_of_mastery integer,
  wins integer,
  battles integer,
  CONSTRAINT account_tanks_global_pkey PRIMARY KEY (account_id, tank_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE account_tanks
  OWNER TO wotstats;
