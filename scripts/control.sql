-- Paquete para auditoría del sistema
-- Proyecto: Sistema de Gestión de Viajes Uber
-- Funcionalidades:
--   - Registrar operaciones críticas (cancelaciones, cambios de estado)
--   - Consultar log de auditoría
--   - Generar reportes de auditoría
--   - Detectar anomalías (múltiples cancelaciones del mismo usuario)

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