# Instalación Base de Datos Uber

## 🚀 Instalación Rápida (3 pasos)

### Paso 1: Crear Usuario (como SYSDBA)
```bash
sqlplus / as sysdba
@tbs_and_user.sql
exit
```

### Paso 2: Crear Tablas
```bash
sqlplus uber_admin/UberAdmin2025@localhost:1521/ORCLPDB1
@create_tables.sql
exit
```

### Paso 3: Cargar Datos CSV
```bash
sqlplus uber_admin/UberAdmin2025@localhost:1521/ORCLPDB1
@setup_load_environment.sql
@execute_load.sql
exit
```

---

## 📋 Descripción de Archivos

### Scripts Principales (ejecutar en orden)
1. **tbs_and_user.sql** - Crea tablespace, usuario y directorio CSV (requiere SYSDBA)
2. **create_tables.sql** - Crea todas las tablas del esquema
3. **setup_load_environment.sql** - Prepara procedimientos de carga
4. **execute_load.sql** - Ejecuta la carga del CSV

### Scripts Adicionales (para después)
- **create_packages.sql** - Paquetes de negocio (TODO)
- **paquete_*.sql** - Lógica de negocio específica (TODO)
- **triggers_control.sql** - Triggers de auditoría (TODO)

### Archivos Obsoletos
- ~~create_user.sql~~ - Usar `tbs_and_user.sql` en su lugar

---

## ⚙️ Configuración

**Servicio:** ORCLPDB1 (cambiar si usas otro)  
**Usuario:** uber_admin  
**Password:** UberAdmin2025  
**CSV:** ncr_ride_bookings.csv (148,770 registros)

---

## 🎯 Modelo Simplificado

Se eliminaron las tablas:
- ❌ TIME_DIMENSION → Columnas en BOOKINGS (booking_date, booking_time)
- ❌ BOOKING_STATUS → CHECK constraint en BOOKINGS.status
- ❌ CANCELLATIONS → Columnas en BOOKINGS (cancelled_by, cancellation_reason, cancelled_at)
