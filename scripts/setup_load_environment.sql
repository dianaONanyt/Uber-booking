-- =====================================================
-- Script: setup_load_environment.sql
-- Descripción: Configuración del entorno para carga de CSV
-- Proyecto: Sistema de Gestión de Viajes Uber
-- Autor: [Tu Nombre]
-- Fecha: 14 de noviembre de 2025
-- =====================================================
-- IMPORTANTE: Ejecutar PRIMERO este script para preparar el entorno
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK ON;

PROMPT '════════════════════════════════════════════════════════';
PROMPT '  CONFIGURACIÓN DE ENTORNO - CARGA CSV UBER';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';

-- =====================================================
-- PASO 1: Crear tabla temporal GLOBAL TEMPORARY
-- =====================================================

PROMPT '[1/4] Creando tabla temporal global...';

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE csv_temp PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE GLOBAL TEMPORARY TABLE csv_temp (
    date_str VARCHAR2(20),
    time_str VARCHAR2(20),
    booking_id VARCHAR2(50),
    booking_status VARCHAR2(50),
    customer_id VARCHAR2(50),
    vehicle_type VARCHAR2(50),
    pickup_location VARCHAR2(100),
    drop_location VARCHAR2(100),
    avg_vtat VARCHAR2(20),
    avg_ctat VARCHAR2(20),
    cancelled_by_customer VARCHAR2(10),
    reason_cancel_customer VARCHAR2(200),
    cancelled_by_driver VARCHAR2(10),
    reason_cancel_driver VARCHAR2(200),
    incomplete_ride VARCHAR2(10),
    reason_incomplete VARCHAR2(200),
    booking_value VARCHAR2(20),
    ride_distance VARCHAR2(20),
    driver_rating VARCHAR2(10),
    customer_rating VARCHAR2(10),
    payment_method VARCHAR2(50)
)
ON COMMIT PRESERVE ROWS;

PROMPT '  ✓ Tabla temporal global creada (datos se mantienen durante sesión)';
PROMPT '';

-- =====================================================
-- PASO 2: Verificar/crear directorio para EXTERNAL TABLE
-- =====================================================

PROMPT '[2/4] Verificando directorio para CSV...';

DECLARE
    v_count NUMBER;
    v_dir_path VARCHAR2(500) := '/Users/davidrodriguez/Downloads/bases2/Proyecto_logistica_portuaria';
BEGIN
    -- Verificar si el directorio ya existe
    SELECT COUNT(*) INTO v_count
    FROM all_directories
    WHERE directory_name = 'CSV_DIR';
    
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ⚠ ATENCIÓN: Directorio CSV_DIR no existe');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  ACCIÓN REQUERIDA (ejecutar como DBA/SYSDBA):');
        DBMS_OUTPUT.PUT_LINE('  ──────────────────────────────────────────────');
        DBMS_OUTPUT.PUT_LINE('  CREATE OR REPLACE DIRECTORY csv_dir AS ''' || v_dir_path || ''';');
        DBMS_OUTPUT.PUT_LINE('  GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  O cambiar el path a la ubicación de tu CSV');
        DBMS_OUTPUT.PUT_LINE('');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ✓ Directorio CSV_DIR encontrado y disponible');
    END IF;
END;
/

PROMPT '';

-- =====================================================
-- PASO 3: Crear procedimientos de carga por tabla
-- =====================================================

PROMPT '[3/4] Creando procedimientos de carga...';

-- Procedimiento 1: Cargar catálogos
CREATE OR REPLACE PROCEDURE sp_load_catalogs AS
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('  CARGANDO CATÁLOGOS');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    
    -- VEHICLE_TYPES
    DBMS_OUTPUT.PUT_LINE('[1/5] VEHICLE_TYPES...');
    INSERT INTO VEHICLE_TYPES (vehicle_type_name)
    SELECT DISTINCT REPLACE(REPLACE(vehicle_type, '"', ''), '''', '')
    FROM csv_temp
    WHERE vehicle_type IS NOT NULL
      AND TRIM(REPLACE(REPLACE(vehicle_type, '"', ''), '''', '')) != 'null';
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('      ✓ ' || v_count || ' tipos insertados');
    
    -- PAYMENT_METHODS
    DBMS_OUTPUT.PUT_LINE('[2/5] PAYMENT_METHODS...');
    
    INSERT INTO PAYMENT_METHODS (method_name)
    SELECT DISTINCT clean_value
    FROM (
        SELECT TRIM(CHR(13) FROM TRIM(CHR(10) FROM TRIM(REPLACE(REPLACE(payment_method, '"', ''), '''', '')))) AS clean_value
        FROM csv_temp
        WHERE payment_method IS NOT NULL
    )
    WHERE LENGTH(clean_value) > 0
      AND clean_value != 'null';
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('      ✓ ' || v_count || ' métodos insertados');
    
    -- BOOKING_STATUS removed: 'status' is modelled as CHECK on BOOKINGS (see create_tables.sql)
    DBMS_OUTPUT.PUT_LINE('[3/5] BOOKING_STATUS: SKIPPED (now CHECK on BOOKINGS)');
    v_count := 0;
    
    -- LOCATIONS
    DBMS_OUTPUT.PUT_LINE('[4/5] LOCATIONS...');
    INSERT INTO LOCATIONS (location_name)
    SELECT DISTINCT location_clean
    FROM (
        SELECT REPLACE(REPLACE(pickup_location, '"', ''), '''', '') AS location_clean
        FROM csv_temp WHERE pickup_location IS NOT NULL
        UNION
        SELECT REPLACE(REPLACE(drop_location, '"', ''), '''', '') AS location_clean
        FROM csv_temp WHERE drop_location IS NOT NULL
    )
    WHERE location_clean IS NOT NULL AND TRIM(location_clean) != 'null';
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('      ✓ ' || v_count || ' ubicaciones insertadas');
    
        -- CANCELLATION_REASONS removed: cancellation reasons will be stored inside BOOKINGS.cancellation_reason
        DBMS_OUTPUT.PUT_LINE('[5/5] CANCELLATION_REASONS: SKIPPED (moved into BOOKINGS.cancellation_reason)');
        v_count := 0;
    
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('  ✓ CATÁLOGOS CARGADOS');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
END;
/

-- Procedimiento: Cargar clientes
CREATE OR REPLACE PROCEDURE sp_load_customers AS
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('  CARGANDO CUSTOMERS');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    
    INSERT INTO CUSTOMERS (customer_id)
    SELECT DISTINCT REPLACE(REPLACE(customer_id, '"', ''), '''', '')
    FROM csv_temp
    WHERE customer_id IS NOT NULL
      AND TRIM(REPLACE(REPLACE(customer_id, '"', ''), '''', '')) != 'null';
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ ' || v_count || ' clientes insertados');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
END;
/

-- Procedimiento: Cargar bookings
CREATE OR REPLACE PROCEDURE sp_load_bookings AS
    v_count NUMBER;
    v_duplicates NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('  CARGANDO BOOKINGS (tabla principal) - time fields and cancellation reasons stored in BOOKINGS');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    
    SELECT COUNT(*) - COUNT(DISTINCT REPLACE(REPLACE(booking_id, '"', ''), '''', ''))
    INTO v_duplicates
    FROM csv_temp;
    
    IF v_duplicates > 0 THEN
        DBMS_OUTPUT.PUT_LINE('  ⚠ Detectados ' || v_duplicates || ' booking_id duplicados - insertando solo primer registro de cada uno');
    END IF;
    
    INSERT INTO BOOKINGS (
       booking_id, booking_date, booking_time, customer_id, vehicle_type_id,
       pickup_location_id, drop_location_id, payment_method_id, status,
       booking_value, ride_distance, driver_arrival_time_minutes, trip_duration_minutes,
       cancelled_by, cancellation_reason, incomplete_reason
    )
    SELECT
       booking_id_clean,
       booking_date,
       booking_time,
       customer_id_clean,
       vehicle_type_id,
       pickup_location_id,
       drop_location_id,
       payment_method_id,
       status_clean,
       booking_value,
       ride_distance,
       driver_arrival_time_minutes,
       trip_duration_minutes,
       cancelled_by,
       cancellation_reason,
       incomplete_reason
    FROM (
        SELECT
           REPLACE(REPLACE(csv.booking_id, '"', ''), '''', '') AS booking_id_clean,
           TO_DATE(REPLACE(REPLACE(csv.date_str, '"', ''), '''', ''), 'YYYY-MM-DD') AS booking_date,
           TO_TIMESTAMP(REPLACE(REPLACE(csv.time_str, '"', ''), '''', ''), 'HH24:MI:SS') AS booking_time,
           REPLACE(REPLACE(csv.customer_id, '"', ''), '''', '') AS customer_id_clean,
           vt.vehicle_type_id,
           pl.location_id AS pickup_location_id,
           dl.location_id AS drop_location_id,
           pm.payment_method_id,
           REPLACE(REPLACE(csv.booking_status, '"', ''), '''', '') AS status_clean,
           CASE WHEN csv.booking_value = 'null' OR TRIM(csv.booking_value) IS NULL 
               THEN NULL ELSE TO_NUMBER(REPLACE(csv.booking_value, '"', '')) END AS booking_value,
           CASE WHEN csv.ride_distance = 'null' OR TRIM(csv.ride_distance) IS NULL 
               THEN NULL ELSE TO_NUMBER(REPLACE(csv.ride_distance, '"', '')) END AS ride_distance,
           CASE WHEN csv.avg_vtat = 'null' OR TRIM(csv.avg_vtat) IS NULL 
               THEN NULL ELSE TO_NUMBER(REPLACE(csv.avg_vtat, '"', '')) END AS driver_arrival_time_minutes,
           CASE WHEN csv.avg_ctat = 'null' OR TRIM(csv.avg_ctat) IS NULL 
               THEN NULL ELSE TO_NUMBER(REPLACE(csv.avg_ctat, '"', '')) END AS trip_duration_minutes,
           CASE WHEN csv.cancelled_by_customer = '1' THEN 'Customer'
               WHEN csv.cancelled_by_driver = '1' THEN 'Driver'
               WHEN csv.incomplete_ride = '1' THEN 'System'
               ELSE NULL END AS cancelled_by,
           CASE WHEN csv.cancelled_by_customer = '1' THEN REPLACE(REPLACE(csv.reason_cancel_customer, '"', ''), '''', '')
               WHEN csv.cancelled_by_driver = '1' THEN REPLACE(REPLACE(csv.reason_cancel_driver, '"', ''), '''', '')
               ELSE NULL END AS cancellation_reason,
           CASE WHEN csv.incomplete_ride = '1' THEN REPLACE(REPLACE(csv.reason_incomplete, '"', ''), '''', '')
               ELSE NULL END AS incomplete_reason,
           ROW_NUMBER() OVER (PARTITION BY REPLACE(REPLACE(csv.booking_id, '"', ''), '''', '') ORDER BY csv.date_str, csv.time_str) AS rn
        FROM csv_temp csv
        LEFT JOIN VEHICLE_TYPES vt ON REPLACE(REPLACE(csv.vehicle_type, '"', ''), '''', '') = vt.vehicle_type_name
        LEFT JOIN LOCATIONS pl ON REPLACE(REPLACE(csv.pickup_location, '"', ''), '''', '') = pl.location_name
        LEFT JOIN LOCATIONS dl ON REPLACE(REPLACE(csv.drop_location, '"', ''), '''', '') = dl.location_name
        LEFT JOIN PAYMENT_METHODS pm ON TRIM(CHR(13) FROM TRIM(CHR(10) FROM TRIM(REPLACE(REPLACE(csv.payment_method, '"', ''), '''', '')))) = pm.method_name
    )
    WHERE rn = 1;
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ ' || TO_CHAR(v_count, '999,999') || ' bookings únicos insertados');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
END;
/

CREATE OR REPLACE PROCEDURE sp_load_cancellations_ratings AS
    v_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    DBMS_OUTPUT.PUT_LINE('  CARGANDO RATINGS');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
    
    INSERT INTO RATINGS (booking_id, driver_rating, customer_rating)
    SELECT
        booking_id_clean,
        driver_rating_num,
        customer_rating_num
    FROM (
        SELECT
            REPLACE(REPLACE(booking_id, '"', ''), '''', '') AS booking_id_clean,
            CASE WHEN driver_rating = 'null' OR TRIM(driver_rating) IS NULL 
                 THEN NULL ELSE TO_NUMBER(REPLACE(driver_rating, '"', '')) END AS driver_rating_num,
            CASE WHEN customer_rating = 'null' OR TRIM(customer_rating) IS NULL 
                 THEN NULL ELSE TO_NUMBER(REPLACE(customer_rating, '"', '')) END AS customer_rating_num,
            ROW_NUMBER() OVER (PARTITION BY REPLACE(REPLACE(booking_id, '"', ''), '''', '') 
                              ORDER BY date_str, time_str) AS rn
        FROM csv_temp
        WHERE (driver_rating IS NOT NULL AND driver_rating != 'null')
           OR (customer_rating IS NOT NULL AND customer_rating != 'null')
    )
    WHERE rn = 1
      AND booking_id_clean IN (SELECT booking_id FROM BOOKINGS);

    v_count := SQL%ROWCOUNT;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('  ✓ ' || TO_CHAR(v_count, '999,999') || ' ratings únicos insertados');
    DBMS_OUTPUT.PUT_LINE('──────────────────────────────────────────────');
END;
/

-- Procedimiento 6: Mostrar resumen
CREATE OR REPLACE PROCEDURE sp_show_summary AS
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('   RESUMEN FINAL - REGISTROS POR TABLA');
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════════════');
    
    FOR rec IN (
        SELECT 'VEHICLE_TYPES' AS tabla, COUNT(*) AS registros FROM VEHICLE_TYPES
        UNION ALL SELECT 'PAYMENT_METHODS', COUNT(*) FROM PAYMENT_METHODS
    UNION ALL SELECT 'LOCATIONS', COUNT(*) FROM LOCATIONS
    UNION ALL SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
    UNION ALL SELECT 'BOOKINGS', COUNT(*) FROM BOOKINGS
    UNION ALL SELECT 'RATINGS', COUNT(*) FROM RATINGS
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD('  ' || rec.tabla, 30) || ': ' || 
                            LPAD(TO_CHAR(rec.registros, '999,999,999'), 12));
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('════════════════════════════════════════════════════════');
END;
/

PROMPT '  ✓ Procedimiento sp_load_catalogs creado';
PROMPT '  ✓ Procedimiento sp_load_customers creado';
PROMPT '  ✓ Procedimiento sp_load_time_dimension creado';
PROMPT '  ✓ Procedimiento sp_load_bookings creado';
PROMPT '  ✓ Procedimiento sp_load_cancellations_ratings creado';
PROMPT '  ✓ Procedimiento sp_show_summary creado';
PROMPT '';

-- =====================================================
-- PASO 4: Crear EXTERNAL TABLE (requiere directorio)
-- =====================================================

PROMPT '[4/4] Creando EXTERNAL TABLE para CSV...';

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE csv_external';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE csv_external (
        date_str VARCHAR2(20),
        time_str VARCHAR2(20),
        booking_id VARCHAR2(50),
        booking_status VARCHAR2(50),
        customer_id VARCHAR2(50),
        vehicle_type VARCHAR2(50),
        pickup_location VARCHAR2(100),
        drop_location VARCHAR2(100),
        avg_vtat VARCHAR2(20),
        avg_ctat VARCHAR2(20),
        cancelled_by_customer VARCHAR2(10),
        reason_cancel_customer VARCHAR2(200),
        cancelled_by_driver VARCHAR2(10),
        reason_cancel_driver VARCHAR2(200),
        incomplete_ride VARCHAR2(10),
        reason_incomplete VARCHAR2(200),
        booking_value VARCHAR2(20),
        ride_distance VARCHAR2(20),
        driver_rating VARCHAR2(10),
        customer_rating VARCHAR2(10),
        payment_method VARCHAR2(50)
    )
    ORGANIZATION EXTERNAL (
        TYPE ORACLE_LOADER
        DEFAULT DIRECTORY csv_dir
        ACCESS PARAMETERS (
            RECORDS DELIMITED BY NEWLINE
            SKIP 1
            FIELDS TERMINATED BY '',''
            MISSING FIELD VALUES ARE NULL
        )
        LOCATION (''ncr_ride_bookings.csv'')
    )
    REJECT LIMIT UNLIMITED';
    
    DBMS_OUTPUT.PUT_LINE('  ✓ EXTERNAL TABLE creada exitosamente');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('No se pudo crear EXTERNAL TABLE');
        DBMS_OUTPUT.PUT_LINE('     Código: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('     Error: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('  SOLUCIÓN: Crear directorio como DBA primero');
        DBMS_OUTPUT.PUT_LINE('  (Ver instrucciones en PASO 2)');
END;
/

PROMPT '';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '  ✓ CONFIGURACIÓN COMPLETADA';
PROMPT '════════════════════════════════════════════════════════';
PROMPT '';
PROMPT 'Objetos creados:';
PROMPT '  • csv_temp (GLOBAL TEMPORARY TABLE)';
PROMPT '  • csv_external (EXTERNAL TABLE)';
PROMPT '  • sp_load_catalogs()';
PROMPT '  • sp_load_customers()';
PROMPT '  • sp_load_time_dimension()';
PROMPT '  • sp_load_bookings()';
PROMPT '  • sp_load_cancellations_ratings()';
PROMPT '  • sp_show_summary()';
PROMPT '';
PROMPT 'Siguiente paso:';
PROMPT '  Ejecutar: @execute_load.sql';
PROMPT '';
