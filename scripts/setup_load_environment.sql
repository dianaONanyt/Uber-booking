-- =====================================================
-- Script: setup_load_environment.sql
-- Configuración del entorno para carga de CSV

-- =====================================================
-- IMPORTANTE: Ejecutar PRIMERO este script para preparar el entorno
-- =====================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET VERIFY OFF;
SET FEEDBACK ON;

PROMPT 'CREACIÓN DE PAQUETE DE CARGA DE DATOS';


ALTER SESSION SET NLS_NUMERIC_CHARACTERS = '.,'; 
-- '.,' significa que el punto es el decimal y la coma es el separador de miles

-- PASO 1: Crear tabla temporal GLOBAL TEMPORARY, Tabla que tiene todas las columnas del CSV

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

PROMPT ' Tabla temporal global creada';

-- =====================================================
-- PASO 2: Verificar/crear directorio para EXTERNAL TABLE, para la lectura del CSV
-- =====================================================

PROMPT '[2/4] Verificando directorio para CSV...';

DECLARE
    v_count NUMBER;
    v_dir_path VARCHAR2(500);
BEGIN
    -- Verificar si el directorio ya existe
    SELECT directory_path INTO v_dir_path
        FROM all_directories 
        WHERE directory_name = 'CSV_DIR';
    SELECT COUNT(*) INTO v_count
    FROM all_directories
    WHERE directory_name = 'CSV_DIR';
    
    IF v_count = 0 THEN
        RAISE directory_not_found;
        DBMS_OUTPUT.PUT_LINE('Directorio CSV_DIR encontrado y disponible');
    END IF;
EXCEPTION
    WHEN directory_not_found THEN
        raise_application_error(-20010, 'El directorio no existe. Debes cambiar el path o crearlo como DBA/SYSDBA.');
    WHEN OTHERS THEN
        raise_application_error(-20010, 'El directorio no existe. Debes cambiar el path o crearlo como DBA/SYSDBA.');
END;
/

PROMPT '';

-- =====================================================
-- PASO 3: Crear procedimientos de carga por tabla, agrupados en un paquete
-- =====================================================

PROMPT '[3/4] Creando procedimientos de carga...';

CREATE OR REPLACE PACKAGE pkg_load_data AS
    PROCEDURE sp_load_vehicle_types;
    PROCEDURE sp_load_payment_methods;
    PROCEDURE sp_load_locations;
    PROCEDURE sp_load_customers;
    PROCEDURE sp_load_ratings;
    PROCEDURE sp_load_bookings;
    PROCEDURE sp_show_summary;
END pkg_load_data;
/

CREATE OR REPLACE PACKAGE BODY pkg_load_data AS
-- Procedimiento 1: Cargar catálogos
    PROCEDURE sp_load_vehicle_types AS
        v_count NUMBER;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('[1/5] VEHICLE_TYPES...');
        INSERT INTO VEHICLE_TYPES (name)
        SELECT DISTINCT REPLACE(REPLACE(vehicle_type, '"', ''), '''', '')
        FROM csv_temp
        WHERE vehicle_type IS NOT NULL
        AND TRIM(REPLACE(REPLACE(vehicle_type, '"', ''), '''', '')) != 'null';
        v_count := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('      ✓ ' || v_count || ' tipos insertados');
        sp_control_register('VEHICLE_TYPES', v_count, 'INSERT');
    END sp_load_vehicle_types;

    PROCEDURE sp_load_payment_methods AS
        v_count NUMBER;
    BEGIN
        -- PAYMENT_METHODS
        DBMS_OUTPUT.PUT_LINE('[2/5] PAYMENT_METHODS...');
        
        INSERT INTO PAYMENT_METHODS (name)
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
        sp_control_register('PAYMENT_METHODS', v_count, 'INSERT');
    END sp_load_payment_methods;

    PROCEDURE sp_load_locations AS
        v_count NUMBER;
    BEGIN
        -- LOCATIONS
        DBMS_OUTPUT.PUT_LINE('[4/5] LOCATIONS...');
        INSERT INTO LOCATIONS (name)
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
        sp_control_register('LOCATIONS', v_count, 'INSERT');
    END sp_load_locations;


    -- Procedimiento: Cargar clientes
    PROCEDURE sp_load_customers AS
        v_count NUMBER;
    BEGIN
        INSERT INTO CUSTOMERS (id)
        SELECT DISTINCT REPLACE(REPLACE(customer_id, '"', ''), '''', '')
        FROM csv_temp
        WHERE customer_id IS NOT NULL
        AND TRIM(REPLACE(REPLACE(customer_id, '"', ''), '''', '')) != 'null';
            
        v_count := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('  ✓ ' || v_count || ' clientes insertados');
        sp_control_register('CUSTOMERS', v_count, 'INSERT');
    END sp_load_customers;

    PROCEDURE sp_load_ratings AS
        v_count NUMBER;
    BEGIN

        -- Se utiliza una CTE (WITH) para obtener las combinaciones únicas de ratings
        -- y luego se aplica la secuencia en el SELECT final.
        INSERT INTO RATINGS (driver_rating, customer_rating)
        WITH distinct_ratings AS (
            SELECT
                -- Convertir a número, manejando NULL y 'null'
                CASE WHEN driver_rating = 'null' OR TRIM(driver_rating) IS NULL
                    THEN NULL 
                    WHEN NOT REGEXP_LIKE(REPLACE(driver_rating, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(driver_rating, '"', '')) 
                END AS driver_rating_num,
                CASE WHEN customer_rating = 'null' OR TRIM(customer_rating) IS NULL
                    THEN NULL 
                    WHEN NOT REGEXP_LIKE(REPLACE(customer_rating, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(customer_rating, '"', '')) 
                END AS customer_rating_num
            FROM csv_temp
            -- Solo consideramos filas donde al menos un rating tiene valor
            WHERE (driver_rating IS NOT NULL AND TRIM(driver_rating) != 'null')
                OR (customer_rating IS NOT NULL AND TRIM(customer_rating) != 'null')
        ),
        new_distinct_ratings AS (
            SELECT DISTINCT
                dr.driver_rating_num,
                dr.customer_rating_num
            FROM distinct_ratings dr
            -- Filtramos los que ya existen en la tabla RATINGS
            MINUS
            SELECT r.driver_rating, r.customer_rating
            FROM RATINGS r
        )
        SELECT
            ndr.driver_rating_num,
            ndr.customer_rating_num
        FROM new_distinct_ratings ndr;

        v_count := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('	✓ ' || TO_CHAR(v_count, '999,999') || ' ratings únicos insertados');
        sp_control_register('RATINGS', v_count, 'INSERT');
    END sp_load_ratings;
    

    PROCEDURE sp_load_bookings AS
        v_count NUMBER;
        v_duplicates NUMBER;
    BEGIN
        
        -- Contar duplicados
        SELECT COUNT(*) - COUNT(DISTINCT REPLACE(REPLACE(booking_id, '"', ''), '''', ''))
        INTO v_duplicates
        FROM csv_temp;

        IF v_duplicates > 0 THEN
            DBMS_OUTPUT.PUT_LINE('	⚠ Detectados ' || v_duplicates || ' booking_id duplicados - insertando solo primer registro de cada uno');
        END IF;

        INSERT INTO BOOKINGS (
            id, booking_date, booking_time, customer_id, vehicle_type_id,
            pickup_location_id, drop_location_id, payment_method_id, status,
            value, ride_distance, driver_arrival_time_minutes, trip_duration_minutes,
            cancelled_by, cancellation_reason, incomplete_reason, rating_id
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
            incomplete_reason,
            rating_id
        FROM (
            SELECT
                REPLACE(REPLACE(csv.booking_id, '"', ''), '''', '') AS booking_id_clean,
                TO_DATE(REPLACE(REPLACE(csv.date_str, '"', ''), '''', ''), 'YYYY-MM-DD') AS booking_date,
                -- Asumimos que date_str es la fecha y time_str es solo la hora
                CAST(TO_DATE('1900-01-01 ' || REPLACE(REPLACE(csv.time_str, '"', ''), '''', ''), 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP(0)) AS booking_time,
                REPLACE(REPLACE(csv.customer_id, '"', ''), '''', '') AS customer_id_clean,
                vh.id AS vehicle_type_id,
                pl.id AS pickup_location_id,
                dl.id AS drop_location_id,
                pm.id AS payment_method_id,
                REPLACE(REPLACE(csv.booking_status, '"', ''), '''', '') AS status_clean,
                -- Métricas y limpieza de valores
                CASE
                    WHEN csv.booking_value IS NULL OR TRIM(csv.booking_value) IN ('', 'null') THEN NULL
                    WHEN NOT REGEXP_LIKE(REPLACE(csv.booking_value, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(csv.booking_value, '"', ''))
                END AS booking_value,
                CASE
                    WHEN csv.ride_distance IS NULL OR TRIM(csv.ride_distance) IN ('', 'null') THEN NULL
                    WHEN NOT REGEXP_LIKE(REPLACE(csv.ride_distance, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(csv.ride_distance, '"', ''))
                END AS ride_distance,
                CASE
                    WHEN csv.avg_vtat IS NULL OR TRIM(csv.avg_vtat) IN ('', 'null') THEN NULL
                    WHEN NOT REGEXP_LIKE(REPLACE(csv.avg_vtat, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(csv.avg_vtat, '"', ''))
                END AS driver_arrival_time_minutes,
                CASE
                    WHEN csv.avg_ctat IS NULL OR TRIM(csv.avg_ctat) IN ('', 'null') THEN NULL
                    WHEN NOT REGEXP_LIKE(REPLACE(csv.avg_ctat, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                    ELSE TO_NUMBER(REPLACE(csv.avg_ctat, '"', ''))
                END AS trip_duration_minutes,

                -- Lógica de Cancelación
                CASE WHEN csv.cancelled_by_customer = '1' THEN 'Customer'
                    WHEN csv.cancelled_by_driver = '1' THEN 'Driver'
                    ELSE NULL END AS cancelled_by,

                -- Razón de Cancelación/Incompleto
                CASE WHEN csv.cancelled_by_customer = '1' THEN REPLACE(REPLACE(csv.reason_cancel_customer, '"', ''), '''', '')
                    WHEN csv.cancelled_by_driver = '1' THEN REPLACE(REPLACE(csv.reason_cancel_driver, '"', ''), '''', '')
                    ELSE NULL END AS cancellation_reason,

                CASE WHEN csv.incomplete_ride = '1' THEN REPLACE(REPLACE(csv.reason_incomplete, '"', ''), '''', '')
                    ELSE NULL END AS incomplete_reason,

                -- Rating FK
                rat.id AS rating_id,

                -- Aseguramos unicidad tomando el primer registro en caso de booking_id duplicados
                ROW_NUMBER() OVER (PARTITION BY REPLACE(REPLACE(csv.booking_id, '"', ''), '''', '') ORDER BY csv.date_str, csv.time_str) AS rn

            FROM csv_temp csv
            LEFT JOIN VEHICLE_TYPES vh ON REPLACE(REPLACE(csv.vehicle_type, '"', ''), '''', '') = vh.name
            LEFT JOIN LOCATIONS pl ON REPLACE(REPLACE(csv.pickup_location, '"', ''), '''', '') = pl.name
            LEFT JOIN LOCATIONS dl ON REPLACE(REPLACE(csv.drop_location, '"', ''), '''', '') = dl.name
            LEFT JOIN PAYMENT_METHODS pm ON TRIM(CHR(13) FROM TRIM(CHR(10) FROM TRIM(REPLACE(REPLACE(csv.payment_method, '"', ''), '''', '')))) = pm.name
            LEFT JOIN RATINGS rat 
                ON NVL(
                        CASE WHEN csv.driver_rating IS NULL OR TRIM(csv.driver_rating) IN ('', 'null') THEN NULL
                            WHEN NOT REGEXP_LIKE(REPLACE(csv.driver_rating, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                            ELSE TO_NUMBER(REPLACE(csv.driver_rating, '"', ''))
                        END,
                        -1
                    ) = NVL(rat.driver_rating, -1)
                AND NVL(
                        CASE WHEN csv.customer_rating IS NULL OR TRIM(csv.customer_rating) IN ('', 'null') THEN NULL
                            WHEN NOT REGEXP_LIKE(REPLACE(csv.customer_rating, '"', ''), '^-?[0-9]+(\.[0-9]+)?$') THEN NULL
                            ELSE TO_NUMBER(REPLACE(csv.customer_rating, '"', ''))
                        END,
                        -1
                    ) = NVL(rat.customer_rating, -1)
        )
        WHERE rn = 1
        -- Asegurarse de que no se inserten booking_id ya existentes
        MINUS
        SELECT 
            b.id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
        FROM BOOKINGS b;


        v_count := SQL%ROWCOUNT;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('	✓ ' || TO_CHAR(v_count, '999,999') || ' bookings únicos insertados');
        sp_control_register('BOOKINGS', v_count, 'INSERT');
    END  sp_load_bookings;

    -- Procedimiento 6: Mostrar resumen
    PROCEDURE sp_show_summary AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('   RESUMEN FINAL - REGISTROS POR TABLA');
        
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
    END sp_show_summary;

END pkg_load_data;
/


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
PROMPT '  ✓ CONFIGURACIÓN COMPLETADA';
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
