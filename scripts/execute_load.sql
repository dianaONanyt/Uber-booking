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

PROMPT ============================================
PROMPT   CARGANDO 148,770 registros desde CSV
PROMPT ============================================

-- =====================================================
-- PASO 1: Cargar CSV a tabla temporal
-- =====================================================
PROMPT [1/5] Cargando CSV...
BEGIN
    DELETE FROM csv_temp;
    INSERT INTO csv_temp SELECT * FROM csv_external;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || SQL%ROWCOUNT || ' registros cargados');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Verifica que el archivo CSV esté en la ruta correcta');
        RAISE;
END;
/

-- =====================================================
-- PASO 2: Cargar catálogos
-- =====================================================
PROMPT [2/5] Cargando catálogos...
BEGIN
    sp_load_catalogs;
END;
/

-- =====================================================
-- PASO 3: Cargar clientes
-- =====================================================
PROMPT [3/5] Cargando clientes...
BEGIN
    sp_load_customers;
END;
/

-- =====================================================
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'; 
-- '.,' significa que el punto es el decimal y la coma es el separador de miles

PROMPT [4/5] Cargando bookings...
BEGIN
    sp_load_bookings;
END;
/

-- =====================================================
-- PASO 5: Cargar ratings
-- =====================================================
PROMPT [5/5] Cargando ratings...
BEGIN
    sp_load_cancellations_ratings;
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

