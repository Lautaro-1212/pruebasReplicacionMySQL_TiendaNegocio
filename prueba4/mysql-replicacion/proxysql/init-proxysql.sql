DELETE FROM mysql_servers;

INSERT INTO mysql_servers (
    hostgroup_id,
    hostname,
    port
)
VALUES
    (10, 'master', 3306),
    (20, 'slave1', 3306),
    (20, 'slave2', 3306);


DELETE FROM mysql_users;

INSERT INTO mysql_users (
    username,
    password,
    default_hostgroup
)
VALUES
    ('app', 'app123', 10);


DELETE FROM mysql_query_rules;

INSERT INTO mysql_query_rules (
    rule_id,
    active,
    match_pattern,
    destination_hostgroup,
    apply
)
VALUES
(
    1,
    1,
    '^SELECT',
    20,
    1
);


LOAD MYSQL SERVERS TO RUNTIME;
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL QUERY RULES TO RUNTIME;


SAVE MYSQL SERVERS TO DISK;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL QUERY RULES TO DISK;