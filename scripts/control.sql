
CREATE OR REPLACE PROCEDURE sp_control_register (
    table_name IN VARCHAR2, 
    rows_affected IN NUMBER, 
    operation_type IN VARCHAR2) 
AS
BEGIN
    INSERT INTO DATA_CONTROL (
        table_name, 
        rows_affected, 
        operation_type, 
        operation_date, 
        responsible_user
    ) VALUES (
        table_name, 
        rows_affected, 
        operation_type, 
        SYSTIMESTAMP, 
        USER
    );
END sp_control_register;
/