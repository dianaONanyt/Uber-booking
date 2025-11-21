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

BEGIN
    DELETE FROM csv_temp;
    INSERT INTO csv_temp SELECT * FROM csv_external;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ ' || SQL%ROWCOUNT || ' registros cargados');
END;
/


CREATE OR REPLACE FUNCTION validate_date(
        p_date_load IN DATE) RETURN BOOLEAN IS
        v_day_of_week VARCHAR2(10);
    BEGIN 
        
        v_day_of_week := TO_CHAR(p_date_load, 'DY', 'NLS_DATE_LANGUAGE=ENGLISH');
        
        IF v_day_of_week IN ('SUN','SAT') THEN
            RAISE_APPLICATION_ERROR(-20010, 'La fecha de carga debe ser un día laboral (Lunes a Viernes).');
        ELSIF TRUNC(p_date_load) < TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20012, 'La fecha de carga no puede ser una fecha pasada.');
        ELSIF p_date_load > SYSDATE + 3 THEN
            RAISE_APPLICATION_ERROR(-20013, 'La fecha de carga no puede ser mayor a 3 días desde hoy.');
        END IF;
        RETURN TRUE;
    EXCEPTION 
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Error al validar la fecha de carga: ' || SQLERRM);
    END validate_date;
/

CREATE OR REPLACE PROCEDURE sp_fill_tables (
        p_date_load IN DATE) AS
BEGIN
    IF validate_date(p_date_load) THEN
        pkg_load_data.sp_load_vehicle_types;
        pkg_load_data.sp_load_payment_methods;
        pkg_load_data.sp_load_locations;
        pkg_load_data.sp_load_customers;
        pkg_load_data.sp_load_ratings;
        pkg_load_data.sp_load_bookings;
        pkg_load_data.sp_show_summary;
    ELSE
        RAISE_APPLICATION_ERROR(-20020, 'La fecha de carga no es válida. Proceso abortado.');
    END IF;
   
END sp_fill_tables;
/
