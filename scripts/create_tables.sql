-- Script para crear las tablas del sistema de gestión de viajes Uber
-- Proyecto: Sistema de Gestión de Viajes Uber
-- Normalización: 3FN (Tercera Forma Normal)

-- ORDEN DE CREACIÓN:
-- 1. Tablas de catálogo (sin dependencias)
-- 2. Tablas de dimensión temporal
-- 3. Tablas transaccionales principales
-- 4. Tablas de detalle (cancelaciones, ratings, etc.)


-- NOTE: Time dimension has been folded into BOOKINGS (date/time stored on each booking)
-- If you still want a separate time dimension for analytics, create it separately.
-- TODO: CREATE TABLE PAYMENT_METHODS
-- TODO: CREATE TABLE BOOKING_STATUS
-- TODO: CREATE TABLE LOCATIONS
-- TODO: CREATE TABLE CUSTOMER_CANCELLATION_REASONS
-- TODO: CREATE TABLE DRIVER_CANCELLATION_REASONS
-- TODO: CREATE TABLE INCOMPLETE_RIDE_REASONS


-- BOOKINGS: tabla central. Estado de la reserva se modela como CHECK constraint
-- (en lugar de una tabla de catálogo separada). Además, razones de
-- cancelación se guardan dentro de esta tabla (cancelled_by, cancellation_reason).
CREATE TABLE BOOKINGS (
	booking_id VARCHAR2(50) PRIMARY KEY,
	booking_date DATE,
	booking_time TIMESTAMP,
	customer_id VARCHAR2(50) NOT NULL,
	driver_id VARCHAR2(50),
	vehicle_type_id VARCHAR2(50),
	pickup_location_id VARCHAR2(50),
	drop_location_id VARCHAR2(50),
	payment_method_id VARCHAR2(50),
	-- Estado como CHECK constraint. Ajustar valores según dataset real si es necesario.
	status VARCHAR2(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING','IN_PROGRESS','COMPLETED','CANCELLED','INCOMPLETE')),
	booking_value NUMBER(12,2),
	ride_distance NUMBER(10,2),
	driver_arrival_time_minutes NUMBER(6),
	trip_duration_minutes NUMBER(6),
	-- Cancelación (si aplica)
	cancelled_by VARCHAR2(20), -- 'Customer' | 'Driver' | 'Incomplete'
	cancellation_reason VARCHAR2(200),
	cancelled_at TIMESTAMP,
	created_at TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- Índices sugeridos
CREATE INDEX IDX_BOOKINGS_DATE ON BOOKINGS(booking_date);
CREATE INDEX IDX_BOOKINGS_STATUS ON BOOKINGS(status);

-- ============================================================
-- TABLAS PRINCIPALES
-- ============================================================

-- TODO: CREATE TABLE CUSTOMERS
-- TODO: CREATE TABLE DRIVERS

-- ============================================================
-- TABLA TRANSACCIONAL CENTRAL
-- ============================================================

-- TODO: CREATE TABLE BOOKINGS

-- ============================================================
-- TABLAS DE DETALLE
-- ============================================================

-- TODO: CREATE TABLE CUSTOMER_CANCELLATIONS
-- TODO: CREATE TABLE DRIVER_CANCELLATIONS
-- TODO: CREATE TABLE INCOMPLETE_RIDES
-- TODO: CREATE TABLE RATINGS

-- ============================================================
-- TABLA DE AUDITORÍA
-- ============================================================

-- TODO: CREATE TABLE AUDIT_LOG

