# Guía de Carga del CSV a Base de Datos

## 📋 Prerequisitos

Antes de cargar el CSV, asegúrate de haber ejecutado:

1. ✅ `tbs_and_user.sql` - Tablespace y usuario
2. ✅ `create_user.sql` - Permisos del usuario
3. ✅ `create_tables.sql` - Estructura de tablas

---

## 🎯 Método PL/SQL Modular ⭐

### Arquitectura de 2 scripts:

**1️⃣ Setup (ejecutar 1 sola vez):**
```bash
sqlplus uber_admin/uber_pass @setup_load_environment.sql
```

**2️⃣ Ejecutar carga (credenciales personalizadas):**
```bash
sqlplus /nolog @execute_load.sql
```

**Ventajas:**
- ✅ 100% PL/SQL nativo (sin Python)
- ✅ Credenciales personalizadas (no hardcodeadas)
- ✅ `GLOBAL TEMPORARY TABLE` (auto-limpieza)
- ✅ 6 procedimientos modulares independientes
- ✅ `PAUSE` entre cada paso para control
- ✅ `EXTERNAL TABLE` (sin SQL*Loader)
- ✅ Manejo de errores con `WHENEVER SQLERROR`
- ✅ Reutilizable: setup 1 vez → ejecutar N veces

**El script setup_load_environment.sql creará:**

1. `GLOBAL TEMPORARY TABLE csv_temp`
2. `EXTERNAL TABLE csv_external` apuntando al CSV
3. 6 procedimientos almacenados:
   - `sp_load_catalogs()` - 5 catálogos
   - `sp_load_customers()` - Clientes con nombres generados
   - `sp_load_time_dimension()` - 13 campos calculados
   - `sp_load_bookings()` - Tabla principal con JOINs
   - `sp_load_cancellations_ratings()` - Cancelaciones y ratings
   - `sp_show_summary()` - Resumen de registros

**El script execute_load.sql hará:**

1. Solicitar usuario, contraseña, conexión
2. Conectarse dinámicamente
3. Verificar que el setup fue ejecutado
4. Cargar CSV → tabla temporal (148,770 registros)
5. Ejecutar procedimientos con PAUSE entre cada uno
6. Mostrar resumen final

**Nota importante:** Requiere crear directorio Oracle primero (como DBA):
```sql
-- Ejecutar como SYS o DBA
CREATE OR REPLACE DIRECTORY csv_dir AS '/Users/davidrodriguez/Downloads/bases2/Proyecto_logistica_portuaria';
GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;
```

**Documentación completa:** Ver `README_CARGA_MODULAR.md`

---

## 🎯 Método 2: Script Python

### Instalación de dependencias:

```bash
pip install pandas cx_Oracle
```

### Ejecución:

```bash
cd scripts
python load_csv_to_oracle.py
```

---

## 🎯 Método 2: Script Python

### Instalación de dependencias:

```bash
pip install pandas cx_Oracle
```

### Ejecución:

```bash
cd scripts
python load_csv_to_oracle.py
```

**Ventajas:**
- ✅ Automático y simple
- ✅ Muestra progreso en tiempo real
- ✅ Maneja errores automáticamente
- ✅ Verifica datos al finalizar
- ✅ No requiere configurar directorios Oracle

---

## 🎯 Método 3: SQL*Loader

### Paso 1: Crear tabla temporal

```sql
sqlplus uber_admin/uber_pass@localhost:1521/XEPDB1

CREATE TABLE csv_temp (
    date_str VARCHAR2(20),
    time_str VARCHAR2(20),
    booking_id VARCHAR2(50),
    booking_status VARCHAR2(50),
    customer_id VARCHAR2(50),
    vehicle_type VARCHAR2(50),
    pickup_location VARCHAR2(100),
    drop_location VARCHAR2(100),
    avg_vtat VARCHAR2(20),
    avg_ctat VARCHAR2(20),
    cancelled_by_customer VARCHAR2(10),
    reason_cancel_customer VARCHAR2(200),
    cancelled_by_driver VARCHAR2(10),
    reason_cancel_driver VARCHAR2(200),
    incomplete_ride VARCHAR2(10),
    reason_incomplete VARCHAR2(200),
    booking_value VARCHAR2(20),
    ride_distance VARCHAR2(20),
    driver_rating VARCHAR2(10),
    customer_rating VARCHAR2(10),
    payment_method VARCHAR2(50)
);
```

### Paso 2: Cargar con SQL*Loader

```bash
cd scripts
sqlldr uber_admin/uber_pass@localhost:1521/XEPDB1 \
       control=load_csv.ctl \
       log=load_csv.log \
       bad=load_csv.bad
```

### Paso 3: Ejecutar script de población

```bash
sqlplus uber_admin/uber_pass@localhost:1521/XEPDB1 @fill_tables.sql
```

---

## 🎯 Método 4: EXTERNAL TABLE Manual (Oracle 12c+)

### Paso 1: Crear directorio en Oracle

```sql
-- Como usuario SYS o DBA
CREATE OR REPLACE DIRECTORY csv_dir AS '/Users/davidrodriguez/Downloads/bases2/Proyecto_logistica_portuaria';
GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;
```

### Paso 2: Crear tabla externa

```sql
CREATE TABLE csv_external (
    date_str VARCHAR2(20),
    time_str VARCHAR2(20),
    booking_id VARCHAR2(50),
    booking_status VARCHAR2(50),
    customer_id VARCHAR2(50),
    vehicle_type VARCHAR2(50),
    pickup_location VARCHAR2(100),
    drop_location VARCHAR2(100),
    avg_vtat VARCHAR2(20),
    avg_ctat VARCHAR2(20),
    cancelled_by_customer VARCHAR2(10),
    reason_cancel_customer VARCHAR2(200),
    cancelled_by_driver VARCHAR2(10),
    reason_cancel_driver VARCHAR2(200),
    incomplete_ride VARCHAR2(10),
    reason_incomplete VARCHAR2(200),
    booking_value VARCHAR2(20),
    ride_distance VARCHAR2(20),
    driver_rating VARCHAR2(10),
    customer_rating VARCHAR2(10),
    payment_method VARCHAR2(50)
)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY csv_dir
    ACCESS PARAMETERS (
        RECORDS DELIMITED BY NEWLINE
        SKIP 1
        FIELDS TERMINATED BY ','
        OPTIONALLY ENCLOSED BY '"'
        MISSING FIELD VALUES ARE NULL
    )
    LOCATION ('ncr_ride_bookings.csv')
)
REJECT LIMIT UNLIMITED;
```

### Paso 3: Cargar a tabla temporal

```sql
CREATE TABLE csv_temp AS SELECT * FROM csv_external;
```

### Paso 4: Ejecutar script de población

```bash
sqlplus uber_admin/uber_pass@localhost:1521/XEPDB1 @fill_tables.sql
```

---

## 📊 Verificación de Datos

Después de la carga, verifica los registros:

```sql
SELECT 'VEHICLE_TYPES' AS tabla, COUNT(*) AS registros FROM VEHICLE_TYPES
UNION ALL
SELECT 'PAYMENT_METHODS', COUNT(*) FROM PAYMENT_METHODS
UNION ALL
SELECT 'BOOKING_STATUS', COUNT(*) FROM BOOKING_STATUS
UNION ALL
SELECT 'LOCATIONS', COUNT(*) FROM LOCATIONS
UNION ALL
SELECT 'CANCELLATION_REASONS', COUNT(*) FROM CANCELLATION_REASONS
UNION ALL
SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMERS
UNION ALL
SELECT 'TIME_DIMENSION', COUNT(*) FROM TIME_DIMENSION
UNION ALL
SELECT 'BOOKINGS', COUNT(*) FROM BOOKINGS
UNION ALL
SELECT 'CANCELLATIONS', COUNT(*) FROM CANCELLATIONS
UNION ALL
SELECT 'RATINGS', COUNT(*) FROM RATINGS;
```

### Registros esperados (aproximados):

| Tabla | Registros Esperados |
|-------|---------------------|
| VEHICLE_TYPES | 6 |
| PAYMENT_METHODS | 5 |
| BOOKING_STATUS | 5 |
| LOCATIONS | ~500 |
| CANCELLATION_REASONS | 12 |
| CUSTOMERS | ~70,000 |
| TIME_DIMENSION | ~140,000 |
| BOOKINGS | 148,770 (todos) |
| CANCELLATIONS | ~37,000 |
| RATINGS | ~98,000 |

---

## 🔍 Consultas de Validación

### Ver tipos de vehículos:
```sql
SELECT * FROM VEHICLE_TYPES;
```

### Ver primeros 10 bookings:
```sql
SELECT b.booking_id, c.customer_name, bs.status_name, b.booking_value
FROM BOOKINGS b
JOIN CUSTOMERS c ON b.customer_id = c.customer_id
JOIN BOOKING_STATUS bs ON b.status_id = bs.status_id
WHERE ROWNUM <= 10;
```

### Ver distribución de cancelaciones:
```sql
SELECT cancelled_by, COUNT(*) AS total
FROM CANCELLATIONS
GROUP BY cancelled_by;
```

### Ver bookings por hora del día:
```sql
SELECT td.hour, COUNT(*) AS total_bookings
FROM BOOKINGS b
JOIN TIME_DIMENSION td ON b.time_id = td.time_id
GROUP BY td.hour
ORDER BY td.hour;
```

---

## ⚠️ Solución de Problemas

### Error: ORA-01843 (Formato de fecha inválido)

**Causa:** Formato de fecha/hora incorrecto en CSV

**Solución:** Verificar que el CSV tenga formato:
- Date: `YYYY-MM-DD` (ej: 2024-03-23)
- Time: `HH24:MI:SS` (ej: 12:29:38)

### Error: ORA-02291 (Violación de integridad referencial)

**Causa:** Intentar insertar BOOKINGS antes que los catálogos

**Solución:** Ejecutar en orden:
1. Catálogos (VEHICLE_TYPES, PAYMENT_METHODS, etc.)
2. CUSTOMERS
3. TIME_DIMENSION
4. BOOKINGS
5. CANCELLATIONS y RATINGS

### Error: Python cx_Oracle no encuentra Oracle Client

**Solución macOS:**
```bash
# Descargar Oracle Instant Client
# https://www.oracle.com/database/technologies/instant-client/downloads.html

# Configurar variable de entorno
export DYLD_LIBRARY_PATH=/path/to/instantclient_19_8:$DYLD_LIBRARY_PATH
```

**Solución alternativa:** Usar método SQL*Loader o EXTERNAL TABLE

---

## 📝 Notas Importantes

1. **Comillas en el CSV:** Los valores vienen entre comillas dobles (`"""CNR123"""`), el script las limpia automáticamente con `REPLACE(campo, '"', '')`

2. **Valores NULL:** En el CSV aparecen como string `"null"`, se convierten a NULL real en la BD

3. **Customer Names:** Se generan automáticamente con patrón `Customer_[ID]` (ej: `Customer_1982111`)

4. **TIME_DIMENSION:** Se calculan 12 campos a partir de Date y Time del CSV

5. **IDs Autoincrementales:** Las secuencias se activan automáticamente con los triggers

---

## 🎓 Para Más Información

- Ver diagrama ER completo: `../modelo/modelo_er.md`
- Ver estructura de tablas: `create_tables.sql`
- Ver documentación completa: `../README.md`
