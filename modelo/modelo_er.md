# Modelo Entidad-Relación - Sistema Uber

## Diagrama ER Simplificado

```mermaid
erDiagram
    %% Entidades principales
    CUSTOMERS ||--o{ BOOKINGS : "realiza"
    VEHICLE_TYPES ||--o{ BOOKINGS : "usa"
    LOCATIONS ||--o{ BOOKINGS : "pickup"
    LOCATIONS ||--o{ BOOKINGS : "dropoff"
    PAYMENT_METHODS ||--o{ BOOKINGS : "paga_con"
    
    %% Relación opcional de ratings
    BOOKINGS ||--o| RATINGS : "recibe"

    CUSTOMERS {
        varchar customer_id PK "CSV: Customer ID"
    }

    VEHICLE_TYPES {
        int vehicle_type_id PK
        varchar vehicle_type_name "CSV: Vehicle Type - CHECK constraint"
    }

    LOCATIONS {
        int location_id PK
        varchar location_name "CSV: Pickup/Drop Location"
    }

    PAYMENT_METHODS {
        int payment_method_id PK
        varchar method_name "CSV: Payment Method - CHECK constraint"
    }

    BOOKINGS {
        varchar booking_id PK "CSV: Booking ID"
        varchar customer_id FK "CSV: Customer ID"
        int vehicle_type_id FK
        int pickup_location_id FK
        int drop_location_id FK
        int payment_method_id FK "NULL si cancelado sin pago"
        varchar status "CSV: Booking Status - CHECK constraint"
        date booking_date "CSV: Date"
        timestamp booking_time "CSV: Time"
        decimal booking_value "CSV: Booking Value"
        decimal ride_distance "CSV: Ride Distance"
        decimal driver_arrival_time_minutes "CSV: Avg VTAT"
        decimal trip_duration_minutes "CSV: Avg CTAT"
        varchar cancelled_by "CSV: Cancelled Rides by - CHECK constraint"
        varchar cancellation_reason "CSV: Reason for cancelling"
        varchar incomplete_reason "CSV: Incomplete Rides Reason"
    }

    RATINGS {
        int rating_id PK
        varchar booking_id FK
        decimal driver_rating "CSV: Driver Ratings"
        decimal customer_rating "CSV: Customer Rating"
    }
```

## Cambios del Modelo Original

### ❌ Entidades Eliminadas
1. **TIME_DIMENSION** → Integrada en BOOKINGS (booking_date, booking_time)
2. **BOOKING_STATUS** → Reemplazada por CHECK constraint en BOOKINGS.status
3. **CANCELLATIONS** → Columnas integradas en BOOKINGS (cancelled_by, cancellation_reason, cancelled_at)
4. **CANCELLATION_REASONS** → Valores directos en BOOKINGS.cancellation_reason

### ✅ Modelo Simplificado
- **BOOKINGS** es la tabla central con todos los datos de tiempo y cancelación
- **Status**: CHECK constraint con 5 valores posibles
- **Cancelaciones**: 3 columnas adicionales en BOOKINGS
- **Tiempo**: 2 columnas (date + timestamp) en vez de tabla separada

## Descripción de Entidades

### CUSTOMERS
Clientes que solicitan viajes (del CSV).
- `customer_id`: ID único del cliente

### VEHICLE_TYPES
Tipos de vehículos (del CSV: Auto, Bike, eBike, Go Mini, Go Sedan, Premier Sedan, Uber XL).
**CHECK constraint** con valores del CSV.

### LOCATIONS
Ubicaciones de recogida y destino (del CSV).

### PAYMENT_METHODS
Métodos de pago (del CSV: Cash, UPI, Debit Card, Credit Card, Uber Wallet).
**CHECK constraint** con valores del CSV.

### BOOKINGS (Tabla Central)
Registro completo de cada reserva del CSV con:
- **status**: CHECK constraint (Completed, Cancelled by Customer, Cancelled by Driver, Incomplete, No Driver Found)
- **cancelled_by**: CHECK constraint (Customer, Driver, System)
- Todos los campos vienen directamente del CSV
- Los NULL son valores originales del CSV

### RATINGS
Calificaciones del CSV (Driver Ratings, Customer Rating).
- NULL cuando no hay calificación en el CSV

## Reglas de Negocio

1. **Status**: CHECK constraint con valores exactos del CSV
2. **Vehicle Types**: CHECK constraint con valores del CSV
3. **Payment Methods**: CHECK constraint con valores del CSV
4. **Cancelled by**: CHECK constraint derivado de las columnas del CSV
5. Todos los datos vienen del CSV, no hay generación automática
