-- =================================================================
-- CREATE TABLES - Sistema Uber
-- =================================================================
-- Basado en: ncr_ride_bookings.csv (148,770 registros)
-- =================================================================

SET ECHO ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK


-- CUSTOMERS: Clientes del CSV 
CREATE TABLE CUSTOMERS (
    id VARCHAR2(50)
) TABLESPACE UBER_TBS;


ALTER TABLE CUSTOMERS 
    ADD CONSTRAINT customer_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX;

-- VEHICLE_TYPES: Tipos de vehículo del CSV
CREATE TABLE VEHICLE_TYPES (
    id NUMBER,
    name VARCHAR2(50) NOT NULL
) TABLESPACE UBER_TBS;

ALTER TABLE VEHICLE_TYPES 
    ADD CONSTRAINT vehicle_type_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX;

-- Secuencia y trigger para el control de la llave primaria
CREATE SEQUENCE vehicle_type_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_vehicle_type_id
BEFORE INSERT ON VEHICLE_TYPES
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := vehicle_type_id_seq.NEXTVAL;
    END IF;
END trg_vehicle_type_id;
/

ALTER TABLE VEHICLE_TYPES ADD (
    CONSTRAINT vehicle_type_name_UN UNIQUE ( name )
    USING INDEX TABLESPACE UBER_IDX
);
ALTER TABLE VEHICLE_TYPES ADD 
    CONSTRAINT vehicle_type_name_CK CHECK ( name IN (
            'Auto',
            'Bike', 
            'eBike',
            'Go Mini',
            'Go Sedan',
            'Premier Sedan',
            'Uber XL'
    ));



-- LOCATIONS: Ubicaciones del CSV (pickup y dropoff) ----------------------------------------------------------
CREATE TABLE LOCATIONS (
    id NUMBER ,
    name VARCHAR2(100) NOT NULL
);

ALTER TABLE LOCATIONS 
    ADD CONSTRAINT location_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX;

ALTER TABLE LOCATIONS ADD
    CONSTRAINT location_name_UN UNIQUE (name)
    USING INDEX TABLESPACE UBER_IDX;  

-- Secuencia y trigger para el control de la llave primaria
CREATE SEQUENCE location_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_location_id
BEFORE INSERT ON LOCATIONS
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := location_id_seq.NEXTVAL;
    END IF;
END trg_location_id;
/

-- PAYMENT_METHODS: Métodos de pago del CSV ----------------------------------------------------------
CREATE TABLE PAYMENT_METHODS (
    id NUMBER,
    name VARCHAR2(50) NOT NULL
);

ALTER TABLE PAYMENT_METHODS 
    ADD CONSTRAINT payment_method_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX; 

ALTER TABLE PAYMENT_METHODS 
    ADD CONSTRAINT method_name_UN UNIQUE (name)
    USING INDEX TABLESPACE UBER_IDX;

ALTER TABLE PAYMENT_METHODS ADD 
    CONSTRAINT method_name_CK CHECK ( name IN (
            'Cash',
            'UPI',
            'Debit Card',
            'Credit Card',
            'Uber Wallet'
        ))
;

-- Secuencia y trigger para el control de la llave primaria
CREATE SEQUENCE payment_method_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_payment_method_id
BEFORE INSERT ON PAYMENT_METHODS
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := payment_method_id_seq.NEXTVAL;
    END IF;
END trg_payment_method_id;
/


-- TABLA DE RATINGS

CREATE TABLE RATINGS (
    id NUMBER,
    driver_rating NUMBER(2,1),
    customer_rating NUMBER(2,1)
);

ALTER TABLE RATINGS 
    ADD CONSTRAINT rating_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX;

-- Secuencia y trigger para el control de la llave primaria
CREATE SEQUENCE rating_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE TRIGGER trg_rating_id
BEFORE INSERT ON RATINGS
FOR EACH ROW
BEGIN
    IF :NEW.id IS NULL THEN
        :NEW.id := rating_id_seq.NEXTVAL;
    END IF;
END trg_rating_id;
/

ALTER TABLE RATINGS ADD (
    CONSTRAINT chk_driver_rating CHECK (driver_rating BETWEEN 0 AND 5 OR driver_rating IS NULL),
    CONSTRAINT chk_customer_rating CHECK (customer_rating BETWEEN 0 AND 5 OR customer_rating IS NULL)
);

-- =================================================================
-- TABLA PRINCIPAL: BOOKINGS
-- =================================================================

CREATE TABLE BOOKINGS (
    id VARCHAR2(50) ,
    customer_id VARCHAR2(50) NOT NULL,
    vehicle_type_id NUMBER,
    pickup_location_id NUMBER,
    drop_location_id NUMBER,
    payment_method_id NUMBER,
    status VARCHAR2(50) NOT NULL,
    booking_date DATE NOT NULL,
    booking_time TIMESTAMP NOT NULL,
    value NUMBER(10,2),
    ride_distance NUMBER(10,2),
    driver_arrival_time_minutes NUMBER(6,2),
    trip_duration_minutes NUMBER(6,2),
    cancelled_by VARCHAR2(20),
    cancellation_reason VARCHAR2(200),
    incomplete_reason VARCHAR2(200),
    rating_id NUMBER
);

ALTER TABLE BOOKINGS 
    ADD CONSTRAINT booking_id_PK PRIMARY KEY (id) 
    USING INDEX TABLESPACE UBER_IDX;

ALTER TABLE BOOKINGS
    ADD CONSTRAINT status_CK CHECK (status IN (
            'Completed',
            'Cancelled by Customer',
            'Cancelled by Driver',
            'Incomplete',
            'No Driver Found',
            'Waiting',
            'Pending',
            'Incomplete',
            'Cancelled'
        ));
ALTER TABLE BOOKINGS
    ADD CONSTRAINT cancelled_by_CK CHECK (cancelled_by IN 
    ('Customer', 'Driver', 'System') OR cancelled_by IS NULL);

--Constraints para relaciones

ALTER TABLE BOOKINGS ADD(
    CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) 
        REFERENCES CUSTOMERS(id),
    CONSTRAINT fk_booking_vehicle FOREIGN KEY (vehicle_type_id) 
        REFERENCES VEHICLE_TYPES(id),
    CONSTRAINT fk_booking_pickup FOREIGN KEY (pickup_location_id) 
        REFERENCES LOCATIONS(id),
    CONSTRAINT fk_booking_dropoff FOREIGN KEY (drop_location_id) 
        REFERENCES LOCATIONS(id),
    CONSTRAINT fk_booking_payment FOREIGN KEY (payment_method_id) 
        REFERENCES PAYMENT_METHODS(id),
    CONSTRAINT fk_booking_rating FOREIGN KEY (rating_id) 
        REFERENCES RATINGS(id)
);



-- CREACIÓN DE TABLA DE CONTROL DE CARGA

CREATE TABLE DATA_CONTROL (
    control_id NUMBER,
    table_name VARCHAR2(100) NOT NULL,
    rows_affected NUMBER,
    operation_type VARCHAR2(20) NOT NULL,
    operation_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    responsible_user VARCHAR2(100)
);

CREATE SEQUENCE data_control_seq START WITH 1 INCREMENT BY 1 NOCACHE;
ALTER TABLE DATA_CONTROL 
    ADD CONSTRAINT data_control_PK PRIMARY KEY (control_id) 
    USING INDEX TABLESPACE UBER_IDX;

CREATE OR REPLACE TRIGGER trg_data_control
BEFORE INSERT ON DATA_CONTROL
FOR EACH ROW
BEGIN
    IF :NEW.control_id IS NULL THEN
        :NEW.control_id := data_control_seq.NEXTVAL;
    END IF;
END trg_data_control;
/


--Tabla de auditoría
CREATE TABLE AUDIT_LOG (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    machine VARCHAR2(50),
    date_time TIMESTAMP DEFAULT SYSTIMESTAMP,
    table_name VARCHAR2(100) NOT NULL,
    operation_type VARCHAR2(20) NOT NULL, 
    old_value VARCHAR2(255),
    new_value VARCHAR2(255),
    performed_by VARCHAR2(50)
);


PROMPT
PROMPT  Tablas creadas exitosamente
PROMPT


