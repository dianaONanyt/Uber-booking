-- =================================================================
-- TRUNCATE DATA - Limpia datos pero mantiene estructura
-- =================================================================

SET ECHO ON
SET FEEDBACK ON

PROMPT LIMPIANDO DATOS (mantiene estructura)
DECLARE
   v_rows_deleted NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_rows_deleted FROM BOOKINGS;
    sp_control_register('Bookings', v_rows_deleted , 'DELETE');
    SELECT COUNT(*) INTO v_rows_deleted FROM RATINGS;
    sp_control_register('Ratings', v_rows_deleted , 'DELETE');
    SELECT COUNT(*) INTO v_rows_deleted FROM CUSTOMERS;
    sp_control_register('Customers', v_rows_deleted , 'DELETE');
    SELECT COUNT(*) INTO v_rows_deleted FROM VEHICLE_TYPES;
    sp_control_register('Vehicle_Types', v_rows_deleted , 'DELETE');
    SELECT COUNT(*) INTO v_rows_deleted FROM LOCATIONS;
    sp_control_register('Locations', v_rows_deleted , 'DELETE');
    SELECT COUNT(*) INTO v_rows_deleted FROM PAYMENT_METHODS;
    sp_control_register('Payment_Methods', v_rows_deleted , 'DELETE');
END;
/
TRUNCATE TABLE BOOKINGS;
TRUNCATE TABLE RATINGS;
TRUNCATE TABLE CUSTOMERS;
TRUNCATE TABLE VEHICLE_TYPES;
TRUNCATE TABLE LOCATIONS;
TRUNCATE TABLE PAYMENT_METHODS;
DELETE FROM csv_temp;


