CREATE DATABASE IF NOT EXISTS tienda;

USE tienda;


CREATE TABLE IF NOT EXISTS productos(

    id INT AUTO_INCREMENT PRIMARY KEY,

    nombre VARCHAR(100)

);



CREATE USER IF NOT EXISTS 'replica'@'%'

IDENTIFIED WITH mysql_native_password BY '1234';



GRANT REPLICATION SLAVE ON *.*

TO 'replica'@'%';




CREATE USER IF NOT EXISTS 'app'@'%'

IDENTIFIED WITH mysql_native_password BY 'app123';



GRANT ALL PRIVILEGES ON tienda.*

TO 'app'@'%';



FLUSH PRIVILEGES;