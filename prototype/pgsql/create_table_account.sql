-- Table: accounts

-- DROP TABLE account;

CREATE TABLE account
(
  account_id integer NOT NULL,
  nickname character(256),
  CONSTRAINT account_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE account
  OWNER TO wotstatsadmins;
