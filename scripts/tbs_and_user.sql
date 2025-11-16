-- =====================================================
-- Script: tbs_and_user.sql
-- Descripción: Crear tablespace y usuario para el sistema
-- Proyecto: Sistema de Gestión de Viajes Uber
-- IMPORTANTE: Ejecutar como SYSDBA
-- =====================================================
-- Ejecutar como: sqlplus / as sysdba @tbs_and_user.sql
-- =====================================================

SET ECHO ON;
SET FEEDBACK ON;

PROMPT '════════════════════════════════════════════════════════';
PROMPT '   CREACIÓN DE TABLESPACE Y USUARIO - UBER BOOKING';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';

-- =====================================================
-- PASO 1: Crear Tablespace
-- =====================================================

PROMPT '[1/3] Creando tablespace UBER_TBS...';

-- Eliminar tablespace si existe (solo para desarrollo/testing)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLESPACE UBER_TBS INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS';
    DBMS_OUTPUT.PUT_LINE(' Tablespace anterior eliminado');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -959 THEN
            DBMS_OUTPUT.PUT_LINE('No existe tablespace previo');
        ELSE
            RAISE;
        END IF;
END;
/

CREATE TABLESPACE UBER_TBS
DATAFILE 'uber_tbs01.dbf' SIZE 100M
AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED
SEGMENT SPACE MANAGEMENT AUTO
EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

PROMPT 'Tablespace UBER_TBS creado exitosamente';
PROMPT '';

-- =====================================================
-- PASO 2: Crear Usuario
-- =====================================================

PROMPT '[2/3] Creando usuario uber_admin...';

-- Eliminar usuario si existe (solo para desarrollo/testing)
BEGIN
    EXECUTE IMMEDIATE 'DROP USER uber_admin CASCADE';
    DBMS_OUTPUT.PUT_LINE('   Usuario anterior eliminado');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -1918 THEN
            DBMS_OUTPUT.PUT_LINE('   No existe usuario previo');
        ELSE
            RAISE;
        END IF;
END;
/

-- Solicitar contraseña (o usar valor por defecto para desarrollo)
ACCEPT v_password CHAR PROMPT 'Contraseña para uber_admin [UberAdmin2025]: ' DEFAULT 'UberAdmin2025' HIDE

CREATE USER uber_admin IDENTIFIED BY &v_password
DEFAULT TABLESPACE UBER_TBS
TEMPORARY TABLESPACE TEMP
QUOTA UNLIMITED ON UBER_TBS;

PROMPT '  ✓ Usuario uber_admin creado';
PROMPT '';

-- =====================================================
-- PASO 3: Asignar Privilegios
-- =====================================================

PROMPT '[3/3] Asignando privilegios...';

-- Privilegios básicos de conexión y recursos
GRANT CONNECT, RESOURCE TO uber_admin;

-- Privilegios para objetos de base de datos
GRANT CREATE VIEW TO uber_admin;
GRANT CREATE SEQUENCE TO uber_admin;
GRANT CREATE TRIGGER TO uber_admin;
GRANT CREATE PROCEDURE TO uber_admin;
GRANT CREATE SYNONYM TO uber_admin;
GRANT CREATE DATABASE LINK TO uber_admin;
GRANT CREATE MATERIALIZED VIEW TO uber_admin;

-- Privilegios para debugging (útil en desarrollo)
GRANT DEBUG CONNECT SESSION TO uber_admin;
GRANT DEBUG ANY PROCEDURE TO uber_admin;

-- Privilegios para directorios (necesario para EXTERNAL TABLES)
GRANT CREATE ANY DIRECTORY TO uber_admin;

-- Privilegios de sistema adicionales
GRANT CREATE TABLE TO uber_admin;
GRANT CREATE SESSION TO uber_admin;
GRANT UNLIMITED TABLESPACE TO uber_admin;

PROMPT '   Privilegios básicos asignados';
PROMPT '   Privilegios de objetos asignados';
PROMPT '   Privilegios de desarrollo asignados';
PROMPT '';

-- =====================================================
-- PASO 4: Crear Directorio para CSV
-- =====================================================

PROMPT '[4/4] Creando directorio para archivos CSV...';

ACCEPT v_csv_path CHAR PROMPT 'Ruta absoluta del directorio CSV [/tmp]: ' DEFAULT '/tmp'

BEGIN
    EXECUTE IMMEDIATE 'DROP DIRECTORY CSV_DIR';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE OR REPLACE DIRECTORY CSV_DIR AS '&v_csv_path';
GRANT READ, WRITE ON DIRECTORY CSV_DIR TO uber_admin;

PROMPT '  ✓ Directorio CSV_DIR creado';
PROMPT '  ✓ Permisos asignados a uber_admin';
PROMPT '';

-- =====================================================
-- Verificación Final
-- =====================================================

PROMPT '════════════════════════════════════════════════════════';
PROMPT '   ✓ CONFIGURACIÓN COMPLETADA';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';
PROMPT 'Usuario creado: uber_admin';
PROMPT 'Tablespace: UBER_TBS (100MB, autoextensible)';
PROMPT 'Directorio CSV: CSV_DIR';
PROMPT '';
PROMPT 'Siguientes pasos:';
PROMPT '  1. Copiar ncr_ride_bookings.csv al directorio configurado';
PROMPT '  2. Conectar como uber_admin:';
PROMPT '     sqlplus uber_admin/UberAdmin2025@localhost:1521/ORCLPDB1';
PROMPT '  3. Ejecutar @create_tables.sql';
PROMPT '';

SET ECHO OFF;

