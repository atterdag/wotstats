-- Table: expected_tank_values_17

-- DROP TABLE expected_tank_values_17;

CREATE TABLE expected_tank_values_17
(
  IDNum integer NOT NULL,
  expFrag numeric,
  expDamage numeric,
  expSpot numeric,
  expDef numeric,
  expWinRate numeric,
  countryid integer,
  tankid integer,
  CONSTRAINT IDNum PRIMARY KEY (IDNum)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE expected_tank_values_17
  OWNER TO wotstatsadmins;
