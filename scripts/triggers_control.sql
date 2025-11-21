-- Script para triggers de control de auditoría

-- TABLA DE RATINGS
CREATE OR REPLACE TRIGGER TR_VALIDAR_RATING
BEFORE INSERT OR UPDATE ON RATINGS
FOR EACH ROW
BEGIN
    IF :NEW.driver_rating IS NOT NULL AND (:NEW.driver_rating < 1.0 OR :NEW.driver_rating > 5.0) THEN
        RAISE_APPLICATION_ERROR(-20010, 'ERROR DE VALIDACIÓN: El rating del conductor debe estar entre 1.0 y 5.0.');
    END IF;

    IF :NEW.customer_rating IS NOT NULL AND (:NEW.customer_rating < 1.0 OR :NEW.customer_rating > 5.0) THEN
        RAISE_APPLICATION_ERROR(-20011, 'ERROR DE VALIDACIÓN: El rating del cliente debe estar entre 1.0 y 5.0.');
    END IF;
    
END;
/

-- TR_VALIDAR_FECHAS_BOOKING
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_VALIDAR_FECHAS_BOOKING
BEFORE UPDATE ON BOOKINGS
FOR EACH ROW
WHEN (
    NEW.status LIKE 'Cancelled%' AND OLD.status NOT LIKE 'Cancelled%'
)
BEGIN
    IF SYSTIMESTAMP < :OLD.booking_time THEN
        RAISE_APPLICATION_ERROR(-20013, 
            'ERROR DE COHERENCIA TEMPORAL: El evento de cancelación no puede ser anterior a la hora de la reserva: ' || 
            TO_CHAR(:OLD.booking_time, 'YYYY-MM-DD HH24:MI:SS')
        );
    END IF;
END;
/

-- =====================================================
-- TRIGGERS DE AUDITORÍA
-- =====================================================

-- TR_AUDIT_BOOKINGS
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_BOOKINGS
AFTER INSERT OR UPDATE OR DELETE ON BOOKINGS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    -- Determinar tipo de operación
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'ID: ' || :NEW.id || ', Status: ' || :NEW.status;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'Status: ' || :OLD.status || ', Value: ' || :OLD.value;
        v_new_value := 'Status: ' || :NEW.status || ', Value: ' || :NEW.value;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.id || ', Status: ' || :OLD.status;
        v_new_value := NULL;
    END IF;

    -- Insertar en AUDIT_LOG
    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'BOOKINGS',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- No fallar la transacción principal por errores de auditoría
END;
/

-- TR_AUDIT_CUSTOMERS
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_CUSTOMERS
AFTER INSERT OR UPDATE OR DELETE ON CUSTOMERS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'ID: ' || :NEW.id;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'ID: ' || :OLD.id;
        v_new_value := 'ID: ' || :NEW.id;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.id;
        v_new_value := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'CUSTOMERS',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- TR_AUDIT_RATINGS
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_RATINGS
AFTER INSERT OR UPDATE OR DELETE ON RATINGS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'Driver: ' || :NEW.driver_rating || ', Customer: ' || :NEW.customer_rating;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'Driver: ' || :OLD.driver_rating || ', Customer: ' || :OLD.customer_rating;
        v_new_value := 'Driver: ' || :NEW.driver_rating || ', Customer: ' || :NEW.customer_rating;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'Driver: ' || :OLD.driver_rating || ', Customer: ' || :OLD.customer_rating;
        v_new_value := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'RATINGS',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- TR_AUDIT_VEHICLE_TYPES
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_VEHICLE_TYPES
AFTER INSERT OR UPDATE OR DELETE ON VEHICLE_TYPES
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'VEHICLE_TYPES',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- TR_AUDIT_LOCATIONS
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_LOCATIONS
AFTER INSERT OR UPDATE OR DELETE ON LOCATIONS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'LOCATIONS',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- TR_AUDIT_PAYMENT_METHODS
-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_PAYMENT_METHODS
AFTER INSERT OR UPDATE OR DELETE ON PAYMENT_METHODS
FOR EACH ROW
DECLARE
    v_operation VARCHAR2(20);
    v_old_value VARCHAR2(255);
    v_new_value VARCHAR2(255);
BEGIN
    IF INSERTING THEN
        v_operation := 'INSERT';
        v_old_value := NULL;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF UPDATING THEN
        v_operation := 'UPDATE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := 'ID: ' || :NEW.id || ', Name: ' || :NEW.name;
    ELSIF DELETING THEN
        v_operation := 'DELETE';
        v_old_value := 'ID: ' || :OLD.id || ', Name: ' || :OLD.name;
        v_new_value := NULL;
    END IF;

    INSERT INTO AUDIT_LOG (
        machine,
        table_name,
        operation_type,
        old_value,
        new_value,
        performed_by
    ) VALUES (
        SYS_CONTEXT('USERENV', 'HOST'),
        'PAYMENT_METHODS',
        v_operation,
        v_old_value,
        v_new_value,
        USER
    );
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/
