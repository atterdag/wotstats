-- Table: accounts

-- DROP TABLE accounts;

CREATE TABLE accounts
(
  account_id integer NOT NULL,
  nickname character(256),
  CONSTRAINT account_id PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE accounts
  OWNER TO wotstatsadmins;
