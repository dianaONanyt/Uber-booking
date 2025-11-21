-- =================================================================
-- CARGA DE DATOS CSV - Uber Booking System
-- =================================================================
-- PREREQUISITOS (ya ejecutados):
--   1. tbs_and_user.sql (como SYSDBA)
--   2. create_tables.sql
--   3. setup_load_environment.sql
-- =================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT   CARGANDO 148,770 registros desde CSV

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'; 

-- =====================================================
-- PASO 1: Cargar CSV a tabla temporal
-- =====================================================
/*
CREATE OR REPLACE PACKAGE pkg_load_data IS

    PROCEDURE validate_date(
        p_fecha_inicio IN DATE);

    PROCEDURE cargar_report_data(
    p_fecha_inicio IN DATE,
    p_fecha_fin IN DATE);
    
    PROCEDURE cargar_tablas(
      fecha_inicio IN DATE, 
      fecha_fin IN DATE);
END pkg_carga_datos;
/*/


PROMPT [1/5] Cargando CSV...

BEGIN
    DELETE FROM csv_temp;
    INSERT INTO csv_temp SELECT * FROM csv_external;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || SQL%ROWCOUNT || ' registros cargados');
END;
/

-- =====================================================
-- PASO 2: Cargar catálogos
-- =====================================================
PROMPT [2/5] Cargando catálogos...
BEGIN
    pkg_load_data.sp_load_vehicle_types;
    pkg_load_data.sp_load_payment_methods;
    pkg_load_data.sp_load_locations;
END;
/

-- =====================================================
-- PASO 3: Cargar clientes
-- =====================================================
PROMPT [3/5] Cargando clientes...
BEGIN
    pkg_load_data.sp_load_customers;
END;
/

-- =====================================================
-- PASO 4: Cargar ratings
-- =====================================================
PROMPT [4/5] Cargando ratings...
BEGIN
    pkg_load_data.sp_load_ratings;
END;
/

-- =====================================================
-- PASO 5: Cargar bookings (incluye tiempo y cancelaciones)
-- =====================================================
PROMPT [5/5] Cargando bookings ...
BEGIN
    pkg_load_data.sp_load_bookings;
END;
/

-- =====================================================
-- RESUMEN
-- =====================================================
PROMPT
PROMPT ============================================
BEGIN
    sp_show_summary;
END;
/
PROMPT ============================================
PROMPT ✓ CARGA COMPLETADA
PROMPT ============================================
