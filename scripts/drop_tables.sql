-- =================================================================
-- LIMPIEZA COMPLETA - Sistema Uber
-- =================================================================
-- Este script elimina TODOS los objetos y datos
-- ADVERTENCIA: No se puede deshacer
-- =================================================================

SET ECHO ON
SET FEEDBACK ON

PROMPT ============================================
PROMPT INICIANDO LIMPIEZA COMPLETA
PROMPT ============================================

-- Eliminar procedimientos
BEGIN
    FOR proc IN (SELECT object_name FROM user_objects WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || proc.object_name;
        DBMS_OUTPUT.PUT_LINE('✓ Procedimiento eliminado: ' || proc.object_name);
    END LOOP;
END;
/

-- Eliminar secuencias
BEGIN
    FOR proc IN (SELECT object_name FROM user_objects WHERE object_type = 'SEQUENCE') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || proc.object_name;
        DBMS_OUTPUT.PUT_LINE('✓ Secuencia eliminada: ' || proc.object_name);
    END LOOP;
END;
/
-- Eliminar TRIGGERS
BEGIN
    FOR proc IN (SELECT object_name FROM user_objects WHERE object_type = 'TRIGGER') LOOP
        EXECUTE IMMEDIATE 'DROP TRIGGER ' || proc.object_name;
        DBMS_OUTPUT.PUT_LINE('✓ Trigger eliminado: ' || proc.object_name);
    END LOOP;
END;
/
-- Eliminar tablas en orden correcto (respetando FKs)
PROMPT
PROMPT Eliminando tablas...

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE BOOKINGS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ BOOKINGS eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  BOOKINGS no existe');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE RATINGS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ RATINGS eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  RATINGS no existe');
END;
/


BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CUSTOMERS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ CUSTOMERS eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  CUSTOMERS no existe');
END;
/


BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE VEHICLE_TYPES CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ VEHICLE_TYPES eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  VEHICLE_TYPES no existe');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LOCATIONS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ LOCATIONS eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  LOCATIONS no existe');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PAYMENT_METHODS CASCADE CONSTRAINTS PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ PAYMENT_METHODS eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  PAYMENT_METHODS no existe');
END;
/

-- Eliminar tablas temporales y externas
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE csv_temp PURGE';
    DBMS_OUTPUT.PUT_LINE('✓ csv_temp eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  csv_temp no existe');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE csv_external';
    DBMS_OUTPUT.PUT_LINE('✓ csv_external eliminada');
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('  csv_external no existe');
END;
/

PROMPT
PROMPT ============================================
PROMPT ✓ LIMPIEZA COMPLETADA
PROMPT ============================================
PROMPT
PROMPT Siguiente paso:
PROMPT   1. @create_tables.sql
PROMPT   2. @setup_load_environment.sql
PROMPT   3. @execute_load.sql
PROMPT ============================================
