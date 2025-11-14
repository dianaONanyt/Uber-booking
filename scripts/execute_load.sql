-- =====================================================
-- Script: execute_load.sql
-- Descripción: Script MAIN para ejecutar carga de CSV
-- Proyecto: Sistema de Gestión de Viajes Uber
-- Autor: [Tu Nombre]
-- Fecha: 14 de noviembre de 2025
-- =====================================================
-- PREREQUISITO: Ejecutar setup_load_environment.sql primero
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK OFF;
SET ECHO OFF;

-- =====================================================
-- Solicitar credenciales al usuario
-- =====================================================

CLEAR SCREEN;

PROMPT '════════════════════════════════════════════════════════';
PROMPT '   CARGA DE DATOS CSV - UBER RIDE ANALYTICS';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';
PROMPT 'Este script cargará los 148,770 registros del CSV';
PROMPT 'a las tablas de la base de datos.';
PROMPT '';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';

-- Solicitar confirmación
ACCEPT v_continue CHAR PROMPT 'Presiona ENTER para continuar o Ctrl+C para cancelar...'

PROMPT '';
PROMPT 'Conectando a la base de datos...';
PROMPT '';

-- Definir variables de sustitución
DEFINE db_user = '&1'
DEFINE db_pass = '&2'
DEFINE db_conn = '&3'

-- Nota: Si no se pasan parámetros, pedir interactivamente
ACCEPT v_user CHAR PROMPT 'Usuario de BD [uber_admin]: ' DEFAULT 'uber_admin'
ACCEPT v_pass CHAR PROMPT 'Contraseña: ' HIDE
ACCEPT v_conn CHAR PROMPT 'Conexión [localhost:1521/XEPDB1]: ' DEFAULT 'localhost:1521/XEPDB1'

-- Conectar con las credenciales proporcionadas
CONNECT &v_user/&v_pass@&v_conn

WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Verificar conexión
SET FEEDBACK ON;
SELECT 'Conectado como: ' || USER || ' en ' || 
       (SELECT sys_context('userenv','db_name') FROM dual) AS estado_conexion 
FROM dual;
SET FEEDBACK OFF;

PROMPT '';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '   INICIANDO PROCESO DE CARGA';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';

-- =====================================================
-- PASO 1: Verificar que setup ya se ejecutó
-- =====================================================

PROMPT '[VERIFICACIÓN] Comprobando entorno...';

DECLARE
    v_count NUMBER;
    v_error VARCHAR2(500);
BEGIN
    -- Verificar tabla temporal
    SELECT COUNT(*) INTO v_count 
    FROM user_tables 
    WHERE table_name = 'CSV_TEMP';
    
    IF v_count = 0 THEN
        v_error := 'Tabla CSV_TEMP no existe';
        RAISE_APPLICATION_ERROR(-20001, v_error || '. Ejecutar setup_load_environment.sql primero');
    END IF;
    
    -- Verificar procedimientos
    SELECT COUNT(*) INTO v_count 
    FROM user_procedures 
    WHERE object_name = 'SP_LOAD_CATALOGS';
    
    IF v_count = 0 THEN
        v_error := 'Procedimientos no encontrados';
        RAISE_APPLICATION_ERROR(-20002, v_error || '. Ejecutar setup_load_environment.sql primero');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('  ✓ Entorno verificado correctamente');
    DBMS_OUTPUT.PUT_LINE('');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  ✗ ERROR: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  SOLUCIÓN: Ejecutar primero:');
        DBMS_OUTPUT.PUT_LINE('    @setup_load_environment.sql');
        DBMS_OUTPUT.PUT_LINE('');
        RAISE;
END;
/

-- =====================================================
-- PASO 2: Cargar CSV a tabla temporal
-- =====================================================

PROMPT '[PASO 1/6] Cargando CSV a tabla temporal...';
PROMPT '';

DECLARE
    v_count NUMBER;
BEGIN
    -- Verificar si csv_temp ya tiene datos
    SELECT COUNT(*) INTO v_count FROM csv_temp;
    
    IF v_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ⚠ Tabla temporal ya tiene ' || v_count || ' registros');
        DBMS_OUTPUT.PUT_LINE('  Limpiando tabla temporal...');
        DELETE FROM csv_temp;
        COMMIT;
    END IF;
    
    -- Cargar desde EXTERNAL TABLE
    BEGIN
        INSERT INTO csv_temp SELECT * FROM csv_external;
        v_count := SQL%ROWCOUNT;
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('  ✓ CSV cargado exitosamente');
        DBMS_OUTPUT.PUT_LINE('  ✓ Registros cargados: ' || TO_CHAR(v_count, '999,999,999'));
        
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'CSV sin datos o no encontrado');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  ✗ ERROR al cargar CSV: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  POSIBLES CAUSAS:');
            DBMS_OUTPUT.PUT_LINE('    1. Directorio CSV_DIR no configurado');
            DBMS_OUTPUT.PUT_LINE('    2. Archivo ncr_ride_bookings.csv no encontrado');
            DBMS_OUTPUT.PUT_LINE('    3. Sin permisos de lectura en el directorio');
            DBMS_OUTPUT.PUT_LINE('');
            DBMS_OUTPUT.PUT_LINE('  SOLUCIÓN ALTERNATIVA:');
            DBMS_OUTPUT.PUT_LINE('    Usar SQL*Loader manualmente:');
            DBMS_OUTPUT.PUT_LINE('    sqlldr ' || USER || '/' || 'password control=load_csv.ctl');
            DBMS_OUTPUT.PUT_LINE('');
            RAISE;
    END;
END;
/



PROMPT '';
PROMPT 'Presiona ENTER para continuar con la carga de catálogos...';
PAUSE

-- =====================================================
-- PASO 3: Cargar catálogos
-- =====================================================

PROMPT '[PASO 2/6] Cargando catálogos...';

BEGIN
    sp_load_catalogs;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR en catálogos: ' || SQLERRM);
        RAISE;
END;
END;

PROMPT '';
PROMPT 'Presiona ENTER para continuar con clientes...';
PAUSE

-- =====================================================
-- PASO 4: Cargar clientes
-- =====================================================

PROMPT '[PASO 3/6] Cargando clientes...';

BEGIN
    sp_load_customers;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR en clientes: ' || SQLERRM);
        RAISE;
END;
/

PROMPT '';
PROMPT 'Presiona ENTER para continuar con dimensión tiempo...';
PAUSE

-- =====================================================
-- PASO 5: Cargar dimensión tiempo
-- =====================================================

PROMPT '[PASO 4/6] Cargando dimensión tiempo...';

BEGIN
    sp_load_time_dimension;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR en time_dimension: ' || SQLERRM);
        RAISE;
END;
/

PROMPT '';
PROMPT 'Presiona ENTER para continuar con bookings...';
PAUSE

-- =====================================================
-- PASO 6: Cargar bookings
-- =====================================================

PROMPT '[PASO 5/6] Cargando bookings (esto puede tomar unos minutos)...';

BEGIN
    sp_load_bookings;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR en bookings: ' || SQLERRM);
        RAISE;
END;
/

PROMPT '';
PROMPT 'Presiona ENTER para continuar con cancelaciones y ratings...';
PAUSE

-- =====================================================
-- PASO 7: Cargar cancelaciones y ratings
-- =====================================================

PROMPT '[PASO 6/6] Cargando cancelaciones y ratings...';

BEGIN
    sp_load_cancellations_ratings;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✗ ERROR en cancelaciones/ratings: ' || SQLERRM);
        RAISE;
END;
/

-- =====================================================
-- PASO 8: Mostrar resumen
-- =====================================================

PROMPT '';
PROMPT '';

BEGIN
    sp_show_summary;
END;
/

PROMPT '';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '   ✓ CARGA COMPLETADA EXITOSAMENTE';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';
PROMPT 'Todos los datos se han cargado correctamente.';
PROMPT '';
PROMPT 'Limpieza (opcional):';
PROMPT '  Para limpiar tabla temporal: DELETE FROM csv_temp;';
PROMPT '  Para eliminar procedimientos: DROP PROCEDURE sp_load_catalogs;';
PROMPT '';
PROMPT 'Próximos pasos:';
PROMPT '  1. Crear triggers de auditoría';
PROMPT '  2. Crear packages de negocio';
PROMPT '  3. Crear índices de optimización';
PROMPT '';

-- Restaurar configuración
SET FEEDBACK ON;
SET VERIFY ON;
SET ECHO ON;
