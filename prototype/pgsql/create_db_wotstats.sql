-- Database: wotstats

-- DROP DATABASE wotstats;

CREATE DATABASE wotstats
  WITH OWNER = wotstatsadmins
       ENCODING = 'UTF8'
       TABLESPACE = pg_default
       CONNECTION LIMIT = -1;
GRANT ALL ON DATABASE wotstats TO wotstatsadmins;
REVOKE ALL ON DATABASE wotstats FROM public;

