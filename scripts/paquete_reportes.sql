
CREATE OR REPLACE PACKAGE PKG_REPORTES AS
    PROCEDURE sp_reporte_por_estado(date_init IN DATE, date_end IN DATE);
    PROCEDURE sp_reporte_por_metodo_pago(date_init IN DATE, date_end IN DATE);
END PKG_REPORTES;
/

CREATE OR REPLACE PACKAGE BODY PKG_REPORTES AS

    PROCEDURE sp_reporte_por_estado(date_init IN DATE, date_end IN DATE) IS
        v_sql VARCHAR2(4000);
        v_meses VARCHAR2(2000);
        v_pivot_meses VARCHAR2(2000);
        v_fecha_inicio DATE := TRUNC(date_init);
        v_fecha_fin DATE := TRUNC(date_end);
        v_mes_actual DATE;
        v_nombre_mes VARCHAR2(20);
    BEGIN
        IF v_fecha_inicio > v_fecha_fin THEN
            raise_application_error(-20001, 'La fecha inicial no puede ser mayor a la fecha final.');
            RETURN;
        END IF;

        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE reporte_estado';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        v_mes_actual := TRUNC(v_fecha_inicio, 'MM');
        v_meses := '';
        v_pivot_meses := '';
    
        WHILE v_mes_actual <= v_fecha_fin LOOP
            v_nombre_mes := UPPER(TO_CHAR(v_mes_actual, 'MONTH'));
            v_nombre_mes := TRIM(v_nombre_mes);
        
            IF v_meses IS NOT NULL THEN
                v_meses := v_meses || ', ';
                v_pivot_meses := v_pivot_meses || ', ';
            END IF;
        
            v_meses := v_meses || v_nombre_mes || ' NUMBER';
            v_pivot_meses := v_pivot_meses || '''' || v_nombre_mes || '''' || ' AS ' || v_nombre_mes;
        
            v_mes_actual := ADD_MONTHS(v_mes_actual, 1);
        END LOOP;

        v_sql := 'CREATE TABLE reporte_estado (STATUS VARCHAR2(100), ' || v_meses || ')';
        EXECUTE IMMEDIATE v_sql;

        v_sql := 'INSERT INTO reporte_estado SELECT * FROM (
        SELECT b.status AS STATUS,
               UPPER(TRIM(TO_CHAR(b.booking_date,''MONTH''))) AS MES
        FROM BOOKINGS b
        WHERE TRUNC(b.booking_date) >= DATE ''' || TO_CHAR(v_fecha_inicio,'YYYY-MM-DD') || '''
        AND TRUNC(b.booking_date) <= DATE ''' || TO_CHAR(v_fecha_fin,'YYYY-MM-DD') || '''
        )
        PIVOT (
            COUNT(*) FOR MES IN (' || v_pivot_meses || ')
        )';
    
        EXECUTE IMMEDIATE v_sql;
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002, 'Error: ' || SQLERRM || ' SQL generado: ' || v_sql);
    END sp_reporte_por_estado;

    PROCEDURE sp_reporte_por_metodo_pago(date_init IN DATE, date_end IN DATE) IS
        v_sql VARCHAR2(4000);
        v_meses VARCHAR2(2000);
        v_pivot_meses VARCHAR2(2000);
        v_fecha_inicio DATE := TRUNC(date_init);
        v_fecha_fin DATE := TRUNC(date_end);
        v_mes_actual DATE;
        v_nombre_mes VARCHAR2(20);
    BEGIN
        IF v_fecha_inicio > v_fecha_fin THEN
            raise_application_error(-20001, 'La fecha inicial no puede ser mayor a la fecha final.');
            RETURN;
        END IF;

        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE reporte_metodo_pago';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        v_mes_actual := TRUNC(v_fecha_inicio, 'MM');
        v_meses := '';
        v_pivot_meses := '';
        
        WHILE v_mes_actual <= v_fecha_fin LOOP
            v_nombre_mes := UPPER(TO_CHAR(v_mes_actual, 'MONTH'));
            v_nombre_mes := TRIM(v_nombre_mes);
            
            IF v_meses IS NOT NULL THEN
                v_meses := v_meses || ', ';
                v_pivot_meses := v_pivot_meses || ', ';
            END IF;
            
            v_meses := v_meses || v_nombre_mes || ' NUMBER';
            v_pivot_meses := v_pivot_meses || '''' || v_nombre_mes || '''' || ' AS ' || v_nombre_mes;
            
            v_mes_actual := ADD_MONTHS(v_mes_actual, 1);
        END LOOP;

        v_sql := 'CREATE TABLE reporte_metodo_pago (method_name VARCHAR2(200), ' || v_meses || ')';
        EXECUTE IMMEDIATE v_sql;

        v_sql := 'INSERT INTO reporte_metodo_pago '
            || 'SELECT * FROM ( '
            || '  SELECT pm.name METHOD_NAME, UPPER(TRIM(TO_CHAR(b.booking_date,''MONTH''))) MES '
            || '  FROM BOOKINGS b '
            || '  JOIN PAYMENT_METHODS pm ON b.payment_method_id = pm.id '
            || '  WHERE TRUNC(b.booking_date) >= DATE ''' || TO_CHAR(v_fecha_inicio, 'YYYY-MM-DD') || ''' '
            || '    AND TRUNC(b.booking_date) <= DATE ''' || TO_CHAR(v_fecha_fin, 'YYYY-MM-DD') || ''' '
            || ') 
            PIVOT ( COUNT(*) FOR MES IN (' || v_pivot_meses || ') )';
        
        EXECUTE IMMEDIATE v_sql;
    EXCEPTION
        WHEN OTHERS THEN
            raise_application_error(-20002, 'Error: ' || SQLERRM || ' SQL generado: ' || v_sql);
    END sp_reporte_por_metodo_pago;

END PKG_REPORTES;
/
