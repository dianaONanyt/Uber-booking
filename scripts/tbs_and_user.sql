-- Script para crear tablespace y usuario
-- Proyecto: Sistema de Gestión de Viajes Uber

-- Conectarse como SYSDBA
-- sqlplus / as sysdba

-- Crear tablespace
-- CREATE TABLESPACE UBER_TBS
-- DATAFILE 'uber_tbs01.dbf' SIZE 100M
-- AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
-- SEGMENT SPACE MANAGEMENT AUTO;

-- Crear usuario
-- CREATE USER uber_admin IDENTIFIED BY <password>
-- DEFAULT TABLESPACE UBER_TBS
-- TEMPORARY TABLESPACE TEMP
-- QUOTA UNLIMITED ON UBER_TBS;

-- Asignar privilegios
-- GRANT CONNECT, RESOURCE TO uber_admin;
-- GRANT CREATE VIEW TO uber_admin;
-- GRANT CREATE SEQUENCE TO uber_admin;
-- GRANT CREATE TRIGGER TO uber_admin;
-- GRANT CREATE PROCEDURE TO uber_admin;
-- GRANT CREATE MATERIALIZED VIEW TO uber_admin;

