# 🚀 Guía de Carga Modular con PL/SQL

## 📋 Descripción

Sistema modular de 2 archivos para cargar el CSV a la base de datos Oracle usando **100% PL/SQL**:

1. **`setup_load_environment.sql`** - Configuración inicial (ejecutar una sola vez)
2. **`execute_load.sql`** - Script MAIN ejecutable (ejecutar cada vez que se necesite cargar datos)

---

## 🎯 Ventajas de este Método

✅ **100% SQL/PL/SQL nativo** - No requiere Python ni herramientas externas  
✅ **Credenciales personalizadas** - Solicita usuario/contraseña al ejecutar  
✅ **Tabla temporal global** - Se limpia automáticamente al cerrar sesión  
✅ **Modular y reutilizable** - Procedimientos independientes por tabla  
✅ **Interactivo** - Pausa entre cada paso para revisar progreso  
✅ **Manejo de errores robusto** - Mensajes claros y soluciones sugeridas  
✅ **EXTERNAL TABLE** - Lee CSV directamente sin SQL*Loader  

---

## 📦 Paso 1: Configuración Inicial (Una sola vez)

### Ejecutar como DBA (requerido para directorio):

```sql
sqlplus sys/password@localhost:1521/XEPDB1 as sysdba

-- Crear directorio para acceder al CSV
CREATE OR REPLACE DIRECTORY csv_dir AS '/Users/davidrodriguez/Downloads/bases2/Proyecto_logistica_portuaria';

-- Dar permisos al usuario
GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;

EXIT;
```

### Ejecutar setup (como usuario de aplicación):

```bash
sqlplus uber_admin/uber_pass@localhost:1521/XEPDB1 @setup_load_environment.sql
```

**Este script crea:**
- `csv_temp` - Tabla temporal global (ON COMMIT PRESERVE ROWS)
- `csv_external` - EXTERNAL TABLE apuntando al CSV
- `sp_load_catalogs()` - Procedimiento para cargar catálogos
- `sp_load_customers()` - Procedimiento para cargar clientes
- `sp_load_time_dimension()` - Procedimiento para dimensión tiempo
- `sp_load_bookings()` - Procedimiento para bookings
- `sp_load_cancellations_ratings()` - Procedimiento para cancelaciones y ratings
- `sp_show_summary()` - Procedimiento para mostrar resumen

---

## 🚀 Paso 2: Ejecutar Carga de Datos

### Modo 1: Sin parámetros (solicita credenciales interactivamente)

```bash
sqlplus /nolog @execute_load.sql
```

Te pedirá:
```
Usuario de BD [uber_admin]: uber_admin
Contraseña: ********
Conexión [localhost:1521/XEPDB1]: localhost:1521/XEPDB1
```

### Modo 2: Con parámetros (sin interacción)

```bash
sqlplus /nolog @execute_load.sql uber_admin uber_pass localhost:1521/XEPDB1
```

---

## 📊 Flujo de Ejecución

```
execute_load.sql
│
├─ [Verificación] Comprobar que setup ya se ejecutó
│  └─ Verifica csv_temp y procedimientos
│
├─ [PASO 1/6] Cargar CSV a tabla temporal
│  └─ INSERT INTO csv_temp SELECT * FROM csv_external
│
├─ [PASO 2/6] Cargar catálogos (PAUSE)
│  ├─ VEHICLE_TYPES (6 registros)
│  ├─ PAYMENT_METHODS (5 registros)
│  ├─ BOOKING_STATUS (5 registros)
│  ├─ LOCATIONS (~500 registros)
│  └─ CANCELLATION_REASONS (12 registros)
│
├─ [PASO 3/6] Cargar clientes (PAUSE)
│  └─ CUSTOMERS (~70,000 con customer_name generado)
│
├─ [PASO 4/6] Cargar dimensión tiempo (PAUSE)
│  └─ TIME_DIMENSION (~140,000 con 13 campos calculados)
│
├─ [PASO 5/6] Cargar bookings (PAUSE)
│  └─ BOOKINGS (148,770 registros con JOINs)
│
├─ [PASO 6/6] Cargar cancelaciones y ratings (PAUSE)
│  ├─ CANCELLATIONS (~37,000)
│  └─ RATINGS (~98,000)
│
└─ [Resumen Final] Mostrar registros por tabla
```

**Nota:** Cada paso tiene un PAUSE para que puedas revisar el progreso. Presiona ENTER para continuar.

---

## 📝 Salida Esperada

```
════════════════════════════════════════════════════════
   CARGA DE DATOS CSV - UBER RIDE ANALYTICS
════════════════════════════════════════════════════════

Este script cargará los 148,770 registros del CSV
a las tablas de la base de datos.

════════════════════════════════════════════════════════

Presiona ENTER para continuar o Ctrl+C para cancelar...

Conectando a la base de datos...

Usuario de BD [uber_admin]: uber_admin
Contraseña: 
Conexión [localhost:1521/XEPDB1]: 

Conectado como: UBER_ADMIN en XEPDB1

════════════════════════════════════════════════════════
   INICIANDO PROCESO DE CARGA
════════════════════════════════════════════════════════

[VERIFICACIÓN] Comprobando entorno...
  ✓ Entorno verificado correctamente

[PASO 1/6] Cargando CSV a tabla temporal...

  ✓ CSV cargado exitosamente
  ✓ Registros cargados:     148,770

Presiona ENTER para continuar con la carga de catálogos...

[PASO 2/6] Cargando catálogos...

──────────────────────────────────────────────
  CARGANDO CATÁLOGOS
──────────────────────────────────────────────
[1/5] VEHICLE_TYPES...
      ✓ 6 tipos insertados
[2/5] PAYMENT_METHODS...
      ✓ 5 métodos insertados
[3/5] BOOKING_STATUS...
      ✓ 5 estados insertados
[4/5] LOCATIONS...
      ✓ 487 ubicaciones insertadas
[5/5] CANCELLATION_REASONS...
      ✓ 12 razones insertadas
──────────────────────────────────────────────
  ✓ CATÁLOGOS CARGADOS
──────────────────────────────────────────────

Presiona ENTER para continuar con clientes...

[PASO 3/6] Cargando clientes...

──────────────────────────────────────────────
  CARGANDO CUSTOMERS
──────────────────────────────────────────────
  ✓  69,845 clientes insertados
──────────────────────────────────────────────

... (continúa con todos los pasos)

════════════════════════════════════════════════════════
   RESUMEN FINAL - REGISTROS POR TABLA
════════════════════════════════════════════════════════
  VEHICLE_TYPES                 :            6
  PAYMENT_METHODS               :            5
  BOOKING_STATUS                :            5
  LOCATIONS                     :          487
  CANCELLATION_REASONS          :           12
  CUSTOMERS                     :       69,845
  TIME_DIMENSION                :      137,234
  BOOKINGS                      :      148,770
  CANCELLATIONS                 :       37,056
  RATINGS                       :       98,165
════════════════════════════════════════════════════════

   ✓ CARGA COMPLETADA EXITOSAMENTE
════════════════════════════════════════════════════════
```

---

## 🔧 Características Técnicas

### Tabla Temporal Global:
```sql
CREATE GLOBAL TEMPORARY TABLE csv_temp (...)
ON COMMIT PRESERVE ROWS;
```
- Los datos persisten durante toda la sesión
- Se limpian automáticamente al desconectar
- No afecta a otras sesiones
- Más eficiente que tabla permanente

### EXTERNAL TABLE:
```sql
CREATE TABLE csv_external (...)
ORGANIZATION EXTERNAL (
    TYPE ORACLE_LOADER
    DEFAULT DIRECTORY csv_dir
    LOCATION ('ncr_ride_bookings.csv')
);
```
- Lee CSV directamente sin cargarlo a BD
- No consume espacio en tablespace
- Acceso mediante SELECT normal
- Sin necesidad de SQL*Loader

### Procedimientos Modulares:
```sql
sp_load_catalogs()           -- Catálogos independientes
sp_load_customers()          -- Clientes con nombres generados
sp_load_time_dimension()     -- 13 campos calculados
sp_load_bookings()           -- JOINs complejos
sp_load_cancellations_ratings()  -- Cancelaciones unificadas
sp_show_summary()            -- Resumen automático
```

---

## ⚠️ Solución de Problemas

### Error: "Tabla CSV_TEMP no existe"
**Causa:** No se ejecutó setup_load_environment.sql  
**Solución:** Ejecutar primero el setup

### Error: "ORA-29913: error in executing ODCIEXTTABLEOPEN callout"
**Causa:** Directorio CSV_DIR no existe o sin permisos  
**Solución:** Ejecutar como DBA:
```sql
CREATE OR REPLACE DIRECTORY csv_dir AS '/ruta/a/tu/csv';
GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;
```

### Error: "CSV sin datos o no encontrado"
**Causa:** Archivo ncr_ride_bookings.csv no está en el directorio  
**Solución:** Verificar ruta y nombre del archivo

### Error: "ORA-02291: integrity constraint violated"
**Causa:** Ejecutar pasos en orden incorrecto  
**Solución:** Dejar que execute_load.sql controle el orden

---

## 🧹 Limpieza (Opcional)

Después de cargar los datos exitosamente:

```sql
-- Limpiar tabla temporal (opcional, se limpia al desconectar)
DELETE FROM csv_temp;
COMMIT;

-- Eliminar EXTERNAL TABLE (opcional)
DROP TABLE csv_external;

-- Eliminar procedimientos (si no los necesitas más)
DROP PROCEDURE sp_load_catalogs;
DROP PROCEDURE sp_load_customers;
DROP PROCEDURE sp_load_time_dimension;
DROP PROCEDURE sp_load_bookings;
DROP PROCEDURE sp_load_cancellations_ratings;
DROP PROCEDURE sp_show_summary;

-- Eliminar tabla temporal (opcional)
DROP TABLE csv_temp;
```

---

## 📊 Comparación de Métodos

| Característica | PL/SQL Modular | Python | SQL*Loader |
|----------------|----------------|--------|------------|
| **Dependencias** | Ninguna ✅ | pandas, cx_Oracle | sqlldr |
| **Credenciales** | Personalizadas ✅ | Hardcoded | Hardcoded |
| **Interactivo** | Sí ✅ | No | No |
| **Modular** | Sí ✅ | Monolítico | + SQL script |
| **Tabla temporal** | GLOBAL TEMP ✅ | Permanente | Permanente |
| **EXTERNAL TABLE** | Sí ✅ | No | No |
| **Progreso visible** | Paso a paso ✅ | Batch | Log file |
| **Reutilizable** | Procedimientos ✅ | Script completo | Control file |

---

## 🎓 Orden de Ejecución Completo

```bash
# 1. Crear tablespace y usuario (como DBA)
sqlplus sys/pass as sysdba @tbs_and_user.sql

# 2. Asignar permisos (como DBA)
sqlplus sys/pass as sysdba @create_user.sql

# 3. Crear tablas (como usuario app)
sqlplus uber_admin/pass @create_tables.sql

# 4. Crear directorio CSV (como DBA) ⭐
sqlplus sys/pass as sysdba
CREATE OR REPLACE DIRECTORY csv_dir AS '/ruta/al/csv';
GRANT READ, WRITE ON DIRECTORY csv_dir TO uber_admin;
EXIT;

# 5. Setup de carga (UNA VEZ) ⭐
sqlplus uber_admin/pass @setup_load_environment.sql

# 6. Ejecutar carga (cada vez que necesites) ⭐
sqlplus /nolog @execute_load.sql
```

---

## 💡 Ventaja Principal

**Un solo comando para cargar todo:**
```bash
sqlplus /nolog @execute_load.sql
```

Y el script:
- ✅ Te solicita credenciales de forma segura
- ✅ Verifica que el entorno esté listo
- ✅ Carga los 148,770 registros paso a paso
- ✅ Te permite pausar entre cada paso
- ✅ Muestra progreso detallado
- ✅ Genera resumen automático
- ✅ Maneja errores con mensajes claros

---

**¿Problemas?** Revisa la sección "Solución de Problemas" arriba o verifica los logs del script.
