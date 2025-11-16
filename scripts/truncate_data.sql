-- =================================================================
-- TRUNCATE DATA - Limpia datos pero mantiene estructura
-- =================================================================
-- Útil para recargar datos sin recrear tablas ni procedimientos
-- =================================================================

SET ECHO ON
SET FEEDBACK ON

PROMPT ============================================
PROMPT LIMPIANDO DATOS (mantiene estructura)
PROMPT ============================================

-- Orden inverso por dependencias FK
TRUNCATE TABLE RATINGS;
TRUNCATE TABLE BOOKINGS;
TRUNCATE TABLE CUSTOMERS;
TRUNCATE TABLE VEHICLE_TYPES;
TRUNCATE TABLE LOCATIONS;
TRUNCATE TABLE PAYMENT_METHODS;
DELETE FROM csv_temp;

PROMPT ============================================
PROMPT ✓ DATOS ELIMINADOS
PROMPT ============================================
PROMPT
PROMPT Siguiente paso:
PROMPT   @execute_load.sql
PROMPT ============================================
