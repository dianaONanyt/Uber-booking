-- Script para crear el usuario y asignar privilegios
-- Proyecto: Sistema de Gestión de Viajes Uber

-- Conectarse como SYSDBA antes de ejecutar este script
-- sqlplus / as sysdba

-- Crear usuario
-- CREATE USER uber_admin IDENTIFIED BY <password>;

-- Asignar privilegios básicos
-- GRANT CONNECT, RESOURCE TO uber_admin;

-- Asignar cuota en el tablespace
-- ALTER USER uber_admin QUOTA UNLIMITED ON UBER_TBS;

-- Privilegios adicionales para PL/SQL
-- GRANT CREATE VIEW TO uber_admin;
-- GRANT CREATE SEQUENCE TO uber_admin;
-- GRANT CREATE TRIGGER TO uber_admin;
-- GRANT CREATE PROCEDURE TO uber_admin;

