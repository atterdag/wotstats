-- Table: accounts

-- DROP TABLE account;

CREATE TABLE account_list
(
  account_id integer NOT NULL,
  nickname character(256),
  CONSTRAINT account_list_global_pkey PRIMARY KEY (account_id)
)
WITH (
  OIDS=FALSE
);
ALTER TABLE account_list
  OWNER TO wotstatsadmins;
