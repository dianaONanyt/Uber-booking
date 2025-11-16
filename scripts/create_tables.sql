-- =================================================================
-- CREATE TABLES - Sistema Uber
-- =================================================================
-- Basado en: ncr_ride_bookings.csv (148,770 registros)
-- Modelo: Solo datos del CSV, CHECK constraints para catálogos
-- =================================================================

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

-- =================================================================
-- TABLAS DE CATÁLOGO
-- =================================================================

-- CUSTOMERS: Clientes del CSV
CREATE TABLE CUSTOMERS (
    customer_id VARCHAR2(50) PRIMARY KEY
);

-- VEHICLE_TYPES: Tipos de vehículo del CSV
CREATE TABLE VEHICLE_TYPES (
    vehicle_type_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_type_name VARCHAR2(50) UNIQUE NOT NULL
        CHECK (vehicle_type_name IN (
            'Auto',
            'Bike', 
            'eBike',
            'Go Mini',
            'Go Sedan',
            'Premier Sedan',
            'Uber XL'
        ))
);

-- LOCATIONS: Ubicaciones del CSV (pickup y dropoff)
CREATE TABLE LOCATIONS (
    location_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_name VARCHAR2(100) UNIQUE NOT NULL
);

-- PAYMENT_METHODS: Métodos de pago del CSV
CREATE TABLE PAYMENT_METHODS (
    payment_method_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    method_name VARCHAR2(50) UNIQUE NOT NULL
        CHECK (method_name IN (
            'Cash',
            'UPI',
            'Debit Card',
            'Credit Card',
            'Uber Wallet'
        ))
);

-- =================================================================
-- TABLA PRINCIPAL: BOOKINGS
-- =================================================================

CREATE TABLE BOOKINGS (
    booking_id VARCHAR2(50) PRIMARY KEY,
    customer_id VARCHAR2(50) NOT NULL,
    vehicle_type_id NUMBER,
    pickup_location_id NUMBER,
    drop_location_id NUMBER,
    payment_method_id NUMBER,
    status VARCHAR2(50) NOT NULL
        CHECK (status IN (
            'Completed',
            'Cancelled by Customer',
            'Cancelled by Driver',
            'Incomplete',
            'No Driver Found'
        )),
    booking_date DATE NOT NULL,
    booking_time TIMESTAMP NOT NULL,
    booking_value NUMBER(10,2),
    ride_distance NUMBER(10,2),
    driver_arrival_time_minutes NUMBER(6,2),
    trip_duration_minutes NUMBER(6,2),
    cancelled_by VARCHAR2(20)
        CHECK (cancelled_by IN ('Customer', 'Driver', 'System') OR cancelled_by IS NULL),
    cancellation_reason VARCHAR2(200),
    incomplete_reason VARCHAR2(200),
    CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) 
        REFERENCES CUSTOMERS(customer_id),
    CONSTRAINT fk_booking_vehicle FOREIGN KEY (vehicle_type_id) 
        REFERENCES VEHICLE_TYPES(vehicle_type_id),
    CONSTRAINT fk_booking_pickup FOREIGN KEY (pickup_location_id) 
        REFERENCES LOCATIONS(location_id),
    CONSTRAINT fk_booking_dropoff FOREIGN KEY (drop_location_id) 
        REFERENCES LOCATIONS(location_id),
    CONSTRAINT fk_booking_payment FOREIGN KEY (payment_method_id) 
        REFERENCES PAYMENT_METHODS(payment_method_id)
);

-- Índices para optimización
CREATE INDEX idx_bookings_date ON BOOKINGS(booking_date);
CREATE INDEX idx_bookings_status ON BOOKINGS(status);
CREATE INDEX idx_bookings_customer ON BOOKINGS(customer_id);

-- =================================================================
-- TABLA DE RATINGS
-- =================================================================

CREATE TABLE RATINGS (
    rating_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id VARCHAR2(50) UNIQUE NOT NULL,
    driver_rating NUMBER(2,1),
    customer_rating NUMBER(2,1),
    CONSTRAINT fk_rating_booking FOREIGN KEY (booking_id) 
        REFERENCES BOOKINGS(booking_id),
    CONSTRAINT chk_driver_rating CHECK (driver_rating BETWEEN 0 AND 5 OR driver_rating IS NULL),
    CONSTRAINT chk_customer_rating CHECK (customer_rating BETWEEN 0 AND 5 OR customer_rating IS NULL)
);

PROMPT
PROMPT ============================================
PROMPT  Tablas creadas exitosamente
PROMPT ============================================
PROMPT
PROMPT Tablas creadas:
PROMPT   - CUSTOMERS
PROMPT   - DRIVERS
PROMPT   - VEHICLE_TYPES (con CHECK constraint)
PROMPT   - LOCATIONS
PROMPT   - PAYMENT_METHODS (con CHECK constraint)
PROMPT   - BOOKINGS (tabla central con CHECK constraints)
PROMPT   - RATINGS
PROMPT ============================================

