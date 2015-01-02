-- Role: wotstats

-- DROP ROLE wotstats;

CREATE ROLE wotstats LOGIN
  NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION;
GRANT wotstatsadmins TO wotstats;
