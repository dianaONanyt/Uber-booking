# Sistema de Gestión de Viajes Uber

## 🚀 Instalación Rápida

### 1. Crear Usuario (como SYSDBA)
```bash
sqlplus / as sysdba
@scripts/tbs_and_user.sql
exit
```

### 2. Crear Tablas
```bash
sqlplus uber_admin/UberAdmin2025@localhost:1521/ORCLPDB1
@scripts/create_tables.sql
exit
```

### 3. Cargar Datos CSV
```bash
sqlplus uber_admin/UberAdmin2025@localhost:1521/ORCLPDB1
@scripts/setup_load_environment.sql
@scripts/execute_load.sql
exit
```

---

## 📊 Dataset
**Uber Ride Analytics 2024** (Kaggle)
- 148,770 registros de viajes
- Archivo: `ncr_ride_bookings.csv`

## 🗂️ Modelo Simplificado
- **BOOKINGS**: Tabla principal con status CHECK, fecha/hora integrada, columnas de cancelación
- **CUSTOMERS, DRIVERS**: Información de usuarios
- **RATINGS**: Calificaciones bidireccionales
- Eliminadas: TIME_DIMENSION, BOOKING_STATUS, CANCELLATIONS (consolidadas en BOOKINGS)

## 📁 Estructura
```
Uber-booking/
├── README.md                  # Esta guía
├── ncr_ride_bookings.csv     # Dataset (148,770 registros)
└── scripts/
    ├── tbs_and_user.sql      # PASO 1: Crear usuario (SYSDBA)
    ├── create_tables.sql     # PASO 2: Crear tablas
    ├── setup_load_environment.sql  # PASO 3a: Preparar carga
    ├── execute_load.sql      # PASO 3b: Ejecutar carga
    └── README.md             # Documentación detallada
```

Ver `scripts/README.md` para más detalles.
Ver archivo: [`modelo/modelo_er.md`](modelo/modelo_er.md)

El modelo incluye un **diagrama Mermaid interactivo** con todas las entidades, relaciones y documentación detallada.

### Entidades Principales

#### 1. **CUSTOMERS** (Clientes)
Información de usuarios que solicitan viajes.
- `customer_id` (PK)
- Datos personales (nombre, email, teléfono)
- Historial de viajes y rating promedio

#### 2. **DRIVERS** (Conductores)
Información de conductores que prestan el servicio.
- `driver_id` (PK)
- Licencia, vehículo asignado, rating promedio
- Viajes completados

#### 3. **BOOKINGS** (Reservas)
Tabla central con todas las reservas de viajes.
- `booking_id` (PK)
- Referencias a cliente, conductor, ubicaciones, método de pago
- Métricas del viaje (distancia, tarifa, tiempos)
- Estado de la reserva

#### 4. **TIME_DIMENSION** (Dimensión Temporal)
Tabla de dimensión para análisis temporal detallado.
- Componentes de fecha (año, mes, día, trimestre)
- Componentes de hora (hora, período del día)
- Banderas (fin de semana, festivo)

#### 5. **LOCATIONS** (Ubicaciones)
Catálogo de ubicaciones de origen y destino.
- Nombre, código de área, ciudad, estado
- Coordenadas geográficas
- Tipo de zona

#### 6. **VEHICLE_TYPES** (Tipos de Vehículo)
Catálogo de tipos de vehículos disponibles.
- Go Mini, Go Sedan, Auto, eBike/Bike, UberXL, Premier Sedan
- Tarifas base y por kilómetro
- Capacidad

#### 7. **PAYMENT_METHODS** (Métodos de Pago)
Catálogo de métodos de pago aceptados.
- UPI, Cash, Credit Card, Uber Wallet, Debit Card
- Comisiones por transacción

#### 8. **RATINGS** (Calificaciones)
Calificaciones bidireccionales cliente ↔ conductor.
- Rating del conductor (1-5)
- Rating del cliente (1-5)
- Comentarios

#### 9. **CANCELLATIONS** + **CANCELLATION_REASONS**
Registro unificado de todas las cancelaciones/incompletos con sus razones.
- Campo `cancelled_by` indica si fue: Customer, Driver o Incomplete
- Campo `reason_type` en CANCELLATION_REASONS categoriza las razones
- 12 razones totales: 5 de clientes + 4 de conductores + 3 de incompletos

### Nivel de Normalización
El modelo está en **Tercera Forma Normal (3FN)**:
- ✅ 1FN: Valores atómicos, sin grupos repetitivos
- ✅ 2FN: No hay dependencias parciales
- ✅ 3FN: No hay dependencias transitivas

### Características Clave del Modelo

#### Enfoque Temporal
La tabla `TIME_DIMENSION` permite análisis sofisticados:
- Patrones de demanda por hora del día
- Comparaciones entre días laborales y fines de semana
- Análisis de temporadas y tendencias
- Identificación de horas pico

#### Trazabilidad Completa
- Cada reserva está vinculada a cliente, conductor, ubicaciones
- Registro de cancelaciones con razones categorizadas
- Calificaciones bidireccionales
- Timestamps en todas las operaciones

#### Flexibilidad
- Catálogos independientes para tipos de vehículos, métodos de pago, ubicaciones
- Fácil agregar nuevas categorías sin modificar esquema
- Separación de razones de cancelación permite análisis detallado

## Instalación y Configuración

### Prerrequisitos
- Oracle Database 19c o superior
- Oracle SQL Developer o SQL*Plus
- Oracle Data Modeler (opcional, para editar el modelo)

### Orden de Ejecución de Scripts

1. **Crear tablespace y usuario**
   ```sql
   @scripts/tbs_and_user.sql
   ```

2. **Crear tablas**
   ```sql
   @scripts/create_tables.sql
   ```

3. **Crear paquetes PL/SQL**
   ```sql
   @scripts/create_packages.sql
   ```

4. **Crear triggers de control**
   ```sql
   @scripts/triggers_control.sql
   ```

5. **Cargar datos iniciales** (opcional)
   ```sql
   @scripts/fill_tables.sql
   ```

## Funcionalidades Pendientes

### Fase 1: Estructura Base
- [ ] Definir todas las tablas con constraints (PK, FK, CHECK, NOT NULL)
- [ ] Crear secuencias para IDs autoincrementales
- [ ] Implementar índices estratégicos para optimización
- [ ] Crear vistas materializadas para reportes frecuentes

### Fase 2: Lógica de Negocio (PL/SQL)
- [ ] **Paquete Gestión de Viajes**: Procedimientos para crear, actualizar, cancelar bookings
- [ ] **Paquete Gestión de Conductores**: Alta, baja, asignación de vehículos, cálculo de ratings
- [ ] **Paquete Reportes**: 
  - Análisis de demanda por hora/día/mes
  - Top rutas más frecuentes
  - Ingresos por método de pago
  - Tasa de cancelación por razón
  - Conductores más eficientes
- [ ] **Paquete Auditoría**: Log automático de operaciones críticas

### Fase 3: Carga de Datos
- [ ] Crear procedimientos de carga masiva desde CSV
- [ ] Validar integridad de datos
- [ ] Poblar tabla TIME_DIMENSION (generar fechas 2024 completo)
- [ ] Importar datos del dataset de Uber

### Fase 4: Triggers y Automatización
- [ ] Trigger: Actualizar `avg_rating` en CUSTOMERS después de cada rating
- [ ] Trigger: Actualizar `avg_rating` en DRIVERS después de cada rating
- [ ] Trigger: Incrementar `total_rides` en CUSTOMERS al completar booking
- [ ] Trigger: Incrementar `total_completed_rides` en DRIVERS al completar booking
- [ ] Trigger: Auditoría automática de cancelaciones
- [ ] Trigger: Validar coherencia de fechas (created_at < cancelled_at)

### Fase 5: Análisis y Optimización
- [ ] Crear índices bitmap para columnas categóricas
- [ ] Implementar particionamiento de BOOKINGS por fecha
- [ ] Crear vistas para consultas comunes
- [ ] Implementar jobs para actualización de estadísticas

## Métricas Clave del Dataset

Según el dataset de Uber 2024:
- **Total de reservas**: 148,770 viajes
- **Tasa de éxito**: 65.96% (93K viajes completados)
- **Tasa de cancelación**: 25% (37.43K cancelaciones)
  - Por cliente: 19.15% (27K)
  - Por conductor: 7.45% (10.5K)
- **Rating promedio de clientes**: 4.40-4.41
- **Rating promedio de conductores**: 4.23-4.24
- **Métodos de pago más usados**: UPI (40%), Cash (25%), Credit Card (15%)

## Autor
Proyecto académico - Base de Datos II

## Tecnologías
- **SGBD**: Oracle Database 19c o superior
- **Herramientas**: SQL Developer, SQL*Plus, Oracle Data Modeler
- **Lenguaje**: SQL, PL/SQL
- **Dataset**: [Kaggle - Uber Ride Analytics 2024](https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard/data)

## Consultas de Negocio Clave

### 1️⃣ Análisis de demanda por hora del día
Identificar horas pico para optimizar disponibilidad de conductores.

### 2️⃣ Top 10 rutas más frecuentes
Detectar rutas de alta demanda para estrategias de pricing dinámico.

### 3️⃣ Tasa de cancelación por razón
Identificar problemas operacionales y áreas de mejora.

### 4️⃣ Conductores más eficientes
Reconocer y premiar conductores con mejor desempeño.

### 5️⃣ Ingresos por método de pago
Optimizar comisiones y promociones según preferencias de pago.

### 6️⃣ Análisis temporal de ratings
Detectar tendencias de satisfacción del cliente.

Ver consultas SQL completas en: [`modelo/modelo_er.md`](modelo/modelo_er.md#consultas-de-negocio-típicas)

## Estado del Proyecto
🟡 **En desarrollo** - Estructura completa, pendiente implementación de lógica de negocio

## Próximos Pasos
1. Implementar DDL completo de todas las tablas
2. Desarrollar paquetes PL/SQL con lógica de negocio
3. Crear triggers para auditoría y actualización automática
4. Cargar datos del CSV al modelo normalizado
5. Crear vistas y reportes para análisis

## Fecha
Noviembre 2025

---

**📊 Dataset**: 148,770 registros | **🚗 Tipos de Vehículo**: 6 | **💳 Métodos de Pago**: 5 | **📅 Período**: Año 2024 completo
