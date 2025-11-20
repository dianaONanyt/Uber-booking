-- Script para triggers de control y auditoría
-- Proyecto: Sistema de Gestión de Viajes Uber




-- TRIGGERS PARA AUDITORÍA

-- =================================================================
-- TRIGGERS DE AUDITORÍA
-- =================================================================

PROMPT '════════════════════════════════════════════════════════';
PROMPT '  COMPILANDO TRIGGERS DE CONTROL Y AUDITORÍA';
PROMPT '════════════════════════════════════════════════════════';

-- ---------------------------------------------------------------
-- TR_AUDIT_CANCELACION

-- ---------------------------------------------------------------
CREATE OR REPLACE TRIGGER TR_AUDIT_CANCELACION
AFTER UPDATE OF status ON BOOKINGS
FOR EACH ROW
WHEN (
    NEW.status LIKE 'Cancelled%' AND OLD.status NOT LIKE 'Cancelled%'
)
DECLARE
    v_cancelled_by VARCHAR2(50);
BEGIN
    v_cancelled_by := COALESCE(:NEW.cancelled_by, 'System'); 
    INSERT INTO AUDIT_LOG (
        booking_id, 
        operation_type, 
        old_value, 
        new_value, 
        performed_by
    )
    VALUES (
        :NEW.booking_id, 
        'CANCEL', 
        :OLD.status, 
        :NEW.status || ' | Reason: ' || :NEW.cancellation_reason,
        v_cancelled_by
    );

EXCEPTION
    WHEN OTHERS THEN
        NULL; 
END;
/

PROMPT '✓ Trigger TR_AUDIT_CANCELACION compilado (Audita cambios de status a Cancelled)';


-- =================================================================
-- TRIGGERS DE VALIDACIÓN
-- =================================================================

-- ---------------------------------------------------------------
-- TR_VALIDAR_RATING
-- Tabla: RATINGS (BEFORE INSERT OR UPDATE)
-- ---------------------------------------------------------------
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

PROMPT '✓ Trigger TR_VALIDAR_RATING compilado (Valida rango 1.0 a 5.0 en RATINGS)';

-- TRIGGERS PARA VALIDACIÓN

-- ---------------------------------------------------------------


-- ---------------------------------------------------------------
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

PROMPT '✓ Trigger TR_VALIDAR_FECHAS_BOOKING compilado (Valida coherencia temporal)';



