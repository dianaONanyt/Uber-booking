-- Script para crear las tablas del sistema de gestión de viajes Uber
-- Proyecto: Sistema de Gestión de Viajes Uber
-- Normalización: 3FN (Tercera Forma Normal)

-- ORDEN DE CREACIÓN:
-- 1. Tablas de catálogo (sin dependencias)
-- 2. Tablas de dimensión temporal
-- 3. Tablas transaccionales principales
-- 4. Tablas de detalle (cancelaciones, ratings, etc.)

-- ============================================================
-- TABLAS DE CATÁLOGO
-- ============================================================

-- TODO: CREATE TABLE VEHICLE_TYPES
-- TODO: CREATE TABLE PAYMENT_METHODS
-- TODO: CREATE TABLE BOOKING_STATUS
-- TODO: CREATE TABLE LOCATIONS
-- TODO: CREATE TABLE CUSTOMER_CANCELLATION_REASONS
-- TODO: CREATE TABLE DRIVER_CANCELLATION_REASONS
-- TODO: CREATE TABLE INCOMPLETE_RIDE_REASONS

-- ============================================================
-- TABLA DE DIMENSIÓN TEMPORAL
-- ============================================================

-- TODO: CREATE TABLE TIME_DIMENSION

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

