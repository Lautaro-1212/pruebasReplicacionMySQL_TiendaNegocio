UPDATE mysql_servers
SET hostgroup_id = 10
WHERE hostname = '${NEW_MASTER}';

UPDATE mysql_servers
SET hostgroup_id = 20
WHERE hostname = '${OLD_MASTER}';

LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;
