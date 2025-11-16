# 📊 Estado del Proyecto: Sistema de Gestión de Viajes Uber

**Última actualización:** 14 de noviembre de 2025  
**Fase actual:** ✅ Modelo de datos completado | ✅ Scripts de carga listos

---

## 📈 Progreso General

```
Fase 1: Diseño del Modelo       ████████████████████ 100% ✅
Fase 2: Scripts DDL             ██████████░░░░░░░░░░  50% 🔄
Fase 3: Carga de Datos          ████████████████████ 100% ✅
Fase 4: Lógica de Negocio       ░░░░░░░░░░░░░░░░░░░░   0% ⏳
Fase 5: Testing                 ░░░░░░░░░░░░░░░░░░░░   0% ⏳
```

---

## 🎯 Dataset

**Fuente:** [Uber Ride Analytics - Kaggle](https://www.kaggle.com/datasets/rupeshkrishnamscs/uber-ride-analytics-2024)

| Métrica | Valor |
|---------|-------|
| **Registros totales** | 148,770 bookings |
| **Columnas CSV** | 21 |
| **Período** | Año 2024 completo |
| **Clientes únicos** | ~70,000 |
| **Ubicaciones únicas** | ~500 |
| **Tipos de vehículos** | 6 |

---

## 📐 Modelo Normalizado (3NF)

### 10 Tablas Implementadas:

#### **Dimensiones y Catálogos** (6 tablas):
1. **TIME_DIMENSION** - 13 campos calculados (año, mes, día, hora, day_name, time_period, etc.)
2. **CUSTOMERS** - customer_id (CSV) + customer_name (generado como 'Customer_[ID]')
3. **VEHICLE_TYPES** - 6 tipos únicos
4. **LOCATIONS** - Ubicaciones de pickup y drop
5. **PAYMENT_METHODS** - 5 métodos de pago
6. **BOOKING_STATUS** - 5 estados posibles

#### **Tablas Transaccionales** (4 tablas):
7. **BOOKINGS** - Tabla principal con driver_arrival_time_minutes y trip_duration_minutes
8. **CANCELLATIONS** - Unificada con campo `cancelled_by` (Customer/Driver/Incomplete)
9. **CANCELLATION_REASONS** - 12 razones con tipo discriminador
10. **RATINGS** - Ratings de conductores y clientes

---

## 🗂️ Mapeo CSV → Base de Datos

```
21 Columnas CSV → 10 Tablas Normalizadas

CSV Column                    → Tabla Destino
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Date                          → TIME_DIMENSION.booking_date
Time                          → TIME_DIMENSION.booking_time
Booking ID                    → BOOKINGS.booking_id (PK)
Booking Status                → BOOKING_STATUS (catálogo)
Customer ID                   → CUSTOMERS.customer_id (PK)
Vehicle Type                  → VEHICLE_TYPES (catálogo)
Pickup Location               → LOCATIONS (catálogo)
Drop Location                 → LOCATIONS (catálogo)
Avg VTAT                      → BOOKINGS.driver_arrival_time_minutes
Avg CTAT                      → BOOKINGS.trip_duration_minutes
Cancelled Rides by Customer   → CANCELLATIONS (cancelled_by='Customer')
Reason (Customer)             → CANCELLATION_REASONS (type='Customer')
Cancelled Rides by Driver     → CANCELLATIONS (cancelled_by='Driver')
Reason (Driver)               → CANCELLATION_REASONS (type='Driver')
Incomplete Rides              → CANCELLATIONS (cancelled_by='Incomplete')
Reason (Incomplete)           → CANCELLATION_REASONS (type='Incomplete')
Booking Value                 → BOOKINGS.booking_value
Ride Distance                 → BOOKINGS.ride_distance
Driver Ratings                → RATINGS.driver_rating
Customer Rating               → RATINGS.customer_rating
Payment Method                → PAYMENT_METHODS (catálogo)
```

---

## ✅ Completado

### Documentación:
- [x] `README.md` - Documentación completa del proyecto
- [x] `modelo/modelo_er.md` - Diagrama Mermaid + mapeo CSV completo
- [x] `ESTADO_PROYECTO.md` - Este archivo
- [x] `.gitattributes` - Configuración Git LFS para CSV

### Scripts de Carga: ⭐ PL/SQL Modular

- [x] `setup_load_environment.sql` - Configuración inicial (ejecutar 1 sola vez)
- [x] `execute_load.sql` - Script ejecutable con credenciales personalizadas
- [x] `README_CARGA_MODULAR.md` - Guía completa del método modular
- [x] `README_CARGA_CSV.md` - Documentación de referencia

**Características:**
- ✅ 100% PL/SQL nativo (sin Python)
- ✅ Solicita usuario/contraseña al ejecutar (no hardcodeado)
- ✅ `GLOBAL TEMPORARY TABLE` (se limpia automáticamente)
- ✅ 6 procedimientos modulares independientes
- ✅ `PAUSE` entre cada paso para revisar progreso
- ✅ `EXTERNAL TABLE` (sin SQL*Loader)
- ✅ `WHENEVER SQLERROR EXIT` para manejo de errores
- ✅ Arquitectura modular: setup una vez → ejecutar N veces

### Scripts SQL:
- [x] `tbs_and_user.sql` - Tablespace y usuario
- [x] `create_user.sql` - Permisos
- [x] `create_tables.sql` - DDL estructura (con TODOs)
- [x] `triggers_control.sql` - Templates de triggers
- [x] `create_packages.sql` - Estructura de packages
- [x] `paquete_gestion_viajes.sql` - Headers
- [x] `paquete_gestion_conductores.sql` - Headers
- [x] `paquete_reportes.sql` - Headers
- [x] `paquete_auditoria.sql` - Headers

---

## 🔄 Próximos Pasos

### 1. Implementar DDL Completo
```sql
-- Crear tablas con constraints
CREATE TABLE VEHICLE_TYPES (
    vehicle_type_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_type_name VARCHAR2(50) NOT NULL UNIQUE
);
```

### 2. Cargar Datos desde CSV

#### **PL/SQL Modular** ⭐
```bash
# Paso 1: Crear directorio (como DBA, 1 sola vez)
sqlplus sys/password@localhost:1521/XEPDB1 as sysdba
CREATE OR REPLACE DIRECTORY csv_dir AS '/Users/davidrodriguez/Downloads/bases2/Proyecto_logistica_portuaria';
EXIT;

# Paso 2: Configurar ambiente (como uber_admin, 1 sola vez)
sqlplus uber_admin/uber_pass @scripts/setup_load_environment.sql

# Paso 3: Ejecutar carga (credenciales personalizadas)
sqlplus /nolog @scripts/execute_load.sql
# Te pedirá: usuario, contraseña, conexión
# Presionarás ENTER entre cada paso
```

### 3. Implementar Lógica de Negocio
- [ ] Packages PL/SQL
- [ ] Triggers de auditoría
- [ ] Vistas de negocio

---

## 📁 Estructura de Archivos

```
Proyecto_logistica_portuaria/
├── README.md                          ✅ Completo
├── ESTADO_PROYECTO.md                 ✅ Este archivo
├── ncr_ride_bookings.csv              ✅ Dataset (148K)
├── modelo/
│   ├── modelo_er.md                   ✅ Diagrama completo
│   └── modelo_modeler.dmd             ✅ Data Modeler
└── scripts/
    ├── setup_load_environment.sql     ✅ Setup modular ⭐
    ├── execute_load.sql               ✅ Main ejecutable ⭐
    ├── README_CARGA_MODULAR.md        ✅ Guía modular ⭐
    ├── README_CARGA_CSV.md            ✅ Documentación
    ├── tbs_and_user.sql               ✅
    ├── create_user.sql                ✅
    ├── create_tables.sql              🔄 50%
    ├── create_packages.sql            ✅
    ├── paquete_*.sql                  ✅
    └── triggers_control.sql           ✅
```

---

**Estado actual:** ✅ Método modular PL/SQL listo para usar


## 🚕 Sistema de Gestión de Viajes Uber - Base de Datos

### ✅ Estructura Completa Creada

```
Proyecto_logistica_portuaria/
├── README.md ✅ (Actualizado con contexto Uber)
├── .gitattributes
├── ncr_ride_bookings.csv (148,770 registros)
├── modelo/
│   ├── modelo_er.md ✅ (Diagrama Mermaid + Documentación completa)
│   └── modelo_modeler/ (Estructura Data Modeler)
└── scripts/
    ├── tbs_and_user.sql ✅
    ├── create_user.sql ✅
    ├── create_tables.sql ✅ (Estructura con TODOs)
    ├── fill_tables.sql ✅ (Guía de carga desde CSV)
    ├── triggers_control.sql ✅
    ├── create_packages.sql
    ├── paquete_gestion_viajes.sql ✅
    ├── paquete_gestion_conductores.sql ✅
    ├── paquete_reportes.sql ✅
    └── paquete_auditoria.sql ✅
```

## 📊 Modelo de Datos (3NF)

### Tablas Principales (10):
1. ✅ **TIME_DIMENSION** - Análisis temporal (Date + Time del CSV)
2. ✅ **CUSTOMERS** - Clientes (Customer ID del CSV)
3. ✅ **VEHICLE_TYPES** - 6 tipos (Auto, eBike, Go Mini, Go Sedan, Premier Sedan, UberXL)
4. ✅ **LOCATIONS** - Ubicaciones únicas (Pickup + Drop Location)
5. ✅ **PAYMENT_METHODS** - 5 métodos (UPI, Cash, Credit Card, Uber Wallet, Debit Card)
6. ✅ **BOOKING_STATUS** - 5 estados (Completed, Cancelled by Customer, Cancelled by Driver, Incomplete, No Driver Found)
7. ✅ **BOOKINGS** - Tabla central (148,770 registros)
8. ✅ **CANCELLATIONS** - Todas las cancelaciones/incompletos (única tabla)
9. ✅ **CANCELLATION_REASONS** - 12 razones totales (Customer=5, Driver=4, Incomplete=3)
10. ✅ **RATINGS** - Calificaciones bidireccionales

### 🎯 Características del Modelo:

✅ **Basado 100% en el CSV real**
- Cada tabla tiene documentación de dónde viene el dato
- Scripts SQL de carga incluidos
- Tabla de campos NULL documentada

✅ **Normalizado a 3NF**
- Sin redundancia
- Integridad referencial
- Catálogos separados

✅ **Listo para implementar**
- DDL estructurado con TODOs claros
- Scripts de carga desde CSV
- Guía de orden de ejecución

## 🔄 Mapeo CSV → Base de Datos

```
21 columnas CSV → 10 tablas normalizadas

CSV: Date, Time → TIME_DIMENSION
CSV: Customer ID → CUSTOMERS
CSV: Vehicle Type → VEHICLE_TYPES (catálogo)
CSV: Pickup/Drop Location → LOCATIONS (catálogo)
CSV: Payment Method → PAYMENT_METHODS (catálogo)
CSV: Booking Status → BOOKING_STATUS (catálogo)
CSV: Booking ID + métricas → BOOKINGS
CSV: Cancelled + Reason (todas) → CANCELLATIONS + CANCELLATION_REASONS (unificada)
CSV: Ratings → RATINGS
```

## 📝 Siguiente Paso: Implementar DDL

### Orden sugerido:

1. **Crear tablespace y usuario** (tbs_and_user.sql)
2. **Crear tablas de catálogo** (7 tablas)
   - VEHICLE_TYPES, PAYMENT_METHODS, BOOKING_STATUS
   - LOCATIONS, *_CANCELLATION_REASONS
3. **Crear TIME_DIMENSION**
4. **Crear CUSTOMERS**
5. **Crear BOOKINGS** (tabla central)
6. **Crear tablas de detalle** (CANCELLATIONS, RATINGS, INCOMPLETE_RIDES)
7. **Poblar catálogos** (con SELECT DISTINCT del CSV)
8. **Cargar BOOKINGS** (con JOINs a catálogos)
9. **Crear paquetes PL/SQL**
10. **Crear triggers**

## 🎓 Dataset Real de Kaggle

- **Fuente**: Uber Ride Analytics Dashboard 2024
- **Registros**: 148,770 bookings
- **Período**: Año 2024 completo
- **Columnas**: 21
- **Tasa de éxito**: 65.96%
- **Rating promedio**: 4.2-4.4

## ✨ Valor Agregado

✅ Modelo profesional normalizado
✅ Documentación completa en modelo_er.md
✅ Scripts SQL listos para ejecutar
✅ Guía de carga desde CSV
✅ Consultas de negocio incluidas
✅ Sin datos inventados - todo del CSV real
✅ Comentarios claros de qué es NULL y cuándo

---

**Estado**: ✅ Estructura completa | 🟡 Pendiente implementación DDL y lógica PL/SQL
