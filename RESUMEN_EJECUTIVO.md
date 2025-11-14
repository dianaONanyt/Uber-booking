# Resumen Ejecutivo: Sistema de Gestión de Viajes Uber

## 📋 Información General

| Atributo | Valor |
|----------|-------|
| **Nombre del Proyecto** | Sistema de Gestión de Viajes Uber |
| **Tipo** | Base de Datos Relacional (Oracle) |
| **Dataset** | Uber Ride Analytics 2024 (Kaggle) |
| **Registros** | 148,770 bookings |
| **Período** | Enero - Diciembre 2024 |
| **Nivel de Normalización** | 3FN (Tercera Forma Normal) |

## 🎯 Objetivos del Proyecto

1. **Diseñar** una base de datos normalizada para gestión de operaciones de ride-sharing
2. **Implementar** lógica de negocio mediante PL/SQL (paquetes, triggers, vistas)
3. **Analizar** patrones de demanda, cancelaciones y satisfacción del cliente
4. **Optimizar** operaciones mediante reportes y métricas clave
5. **Garantizar** integridad referencial y auditoría de operaciones críticas

## 🏗️ Arquitectura del Modelo

### Entidades Principales (15 tablas)

#### Tablas de Catálogo (7)
1. `VEHICLE_TYPES` - Tipos de vehículos disponibles
2. `PAYMENT_METHODS` - Métodos de pago aceptados
3. `BOOKING_STATUS` - Estados de reserva
4. `LOCATIONS` - Ubicaciones de origen y destino
5. `CUSTOMER_CANCELLATION_REASONS` - Razones de cancelación por cliente
6. `DRIVER_CANCELLATION_REASONS` - Razones de cancelación por conductor
7. `INCOMPLETE_RIDE_REASONS` - Razones de viajes incompletos

#### Tablas de Dimensión (1)
8. `TIME_DIMENSION` - Dimensión temporal para análisis

#### Tablas Principales (2)
9. `CUSTOMERS` - Información de clientes
10. `DRIVERS` - Información de conductores

#### Tabla Transaccional Central (1)
11. `BOOKINGS` - Registro de todas las reservas

#### Tablas de Detalle (4)
12. `CUSTOMER_CANCELLATIONS` - Cancelaciones por cliente
13. `DRIVER_CANCELLATIONS` - Cancelaciones por conductor
14. `INCOMPLETE_RIDES` - Viajes incompletos
15. `RATINGS` - Calificaciones bidireccionales

## 📊 Estadísticas del Dataset

### Volumen de Operaciones
- **Total de bookings**: 148,770
- **Viajes completados**: 93,000 (65.96%)
- **Cancelaciones totales**: 37,430 (25%)
  - Por cliente: 27,000 (19.15%)
  - Por conductor: 10,500 (7.45%)

### Distribución de Vehículos
| Tipo | Bookings | Tasa Éxito | Distancia Prom. |
|------|----------|------------|-----------------|
| Auto | 12.88M | 91.1% | 25.99 km |
| eBike/Bike | 11.46M | 91.1% | 26.11 km |
| Go Mini | 10.34M | 91.0% | 25.99 km |
| Go Sedan | 9.37M | 91.1% | 25.98 km |
| Premier Sedan | 6.28M | 91.2% | 25.95 km |
| UberXL | 1.53M | 92.2% | 25.72 km |

### Métodos de Pago
1. **UPI**: 40% de ingresos
2. **Cash**: 25% de ingresos
3. **Credit Card**: 15% de ingresos
4. **Uber Wallet**: 12% de ingresos
5. **Debit Card**: 8% de ingresos

### Calificaciones
- **Rating promedio de clientes**: 4.40 - 4.41 ⭐
- **Rating promedio de conductores**: 4.23 - 4.24 ⭐

## 🔑 Características Clave del Diseño

### 1. Enfoque Temporal
La tabla `TIME_DIMENSION` permite:
- ✅ Análisis por hora del día (identificar horas pico)
- ✅ Comparación días laborales vs. fines de semana
- ✅ Análisis de temporadas y tendencias
- ✅ Identificación de días festivos

### 2. Normalización 3FN
- ✅ Eliminación de redundancia de datos
- ✅ No hay dependencias transitivas
- ✅ Integridad referencial garantizada
- ✅ Facilidad para agregar nuevas categorías

### 3. Trazabilidad Completa
- ✅ Cada booking vinculado a cliente, conductor, ubicaciones
- ✅ Registro detallado de cancelaciones con razones
- ✅ Calificaciones bidireccionales (cliente ↔ conductor)
- ✅ Timestamps en todas las operaciones

### 4. Flexibilidad
- ✅ Catálogos independientes fáciles de mantener
- ✅ Separación de razones de cancelación permite análisis detallado
- ✅ Modelo extensible sin modificar estructura base

## 📈 Casos de Uso Principales

### Operacionales
1. Crear nueva reserva
2. Asignar conductor a reserva
3. Cancelar reserva (cliente o conductor)
4. Completar viaje y procesar pago
5. Registrar calificaciones

### Analíticos
1. Identificar horas pico de demanda
2. Analizar rutas más frecuentes
3. Calcular tasas de cancelación por razón
4. Evaluar desempeño de conductores
5. Proyectar ingresos por método de pago
6. Detectar patrones de fraude o abuso

### Administrativos
1. Gestionar alta/baja de conductores
2. Configurar tarifas por tipo de vehículo
3. Auditar operaciones críticas
4. Generar reportes ejecutivos

## 🛠️ Tecnologías y Herramientas

- **SGBD**: Oracle Database 19c+
- **Lenguajes**: SQL, PL/SQL
- **Herramientas**: SQL Developer, Oracle Data Modeler
- **Modelado**: Diagramas Mermaid ER
- **Control de Versiones**: Git

## 📦 Componentes del Sistema

### Scripts SQL
1. `tbs_and_user.sql` - Tablespace y usuario
2. `create_tables.sql` - DDL de todas las tablas
3. `fill_tables.sql` - Carga de datos desde CSV
4. `create_packages.sql` - Paquetes PL/SQL
5. `triggers_control.sql` - Triggers de auditoría

### Paquetes PL/SQL
1. **PKG_GESTION_VIAJES** - CRUD de bookings
2. **PKG_GESTION_CONDUCTORES** - Gestión de drivers
3. **PKG_REPORTES** - Análisis y métricas
4. **PKG_AUDITORIA** - Log de operaciones

## 🎓 Aprendizajes Esperados

### Conceptos de Base de Datos
- ✅ Normalización (1FN, 2FN, 3FN)
- ✅ Diseño de modelos ER complejos
- ✅ Integridad referencial
- ✅ Índices y optimización

### PL/SQL
- ✅ Paquetes (specification + body)
- ✅ Triggers (BEFORE/AFTER INSERT/UPDATE/DELETE)
- ✅ Cursores y excepciones
- ✅ Procedimientos almacenados

### Análisis de Datos
- ✅ Consultas complejas con JOINs múltiples
- ✅ Funciones de agregación y GROUP BY
- ✅ Análisis temporal con DATE functions
- ✅ Subconsultas correlacionadas

## 🚀 Roadmap de Implementación

### Fase 1: Estructura (Semana 1)
- [x] Diseñar modelo ER
- [x] Crear estructura de carpetas
- [ ] Implementar DDL completo
- [ ] Crear índices y constraints

### Fase 2: Datos (Semana 2)
- [ ] Poblar tablas de catálogo
- [ ] Generar TIME_DIMENSION
- [ ] Cargar datos desde CSV
- [ ] Validar integridad

### Fase 3: Lógica (Semana 3-4)
- [ ] Implementar paquetes PL/SQL
- [ ] Crear triggers
- [ ] Desarrollar vistas
- [ ] Probar procedimientos

### Fase 4: Análisis (Semana 5)
- [ ] Ejecutar consultas de negocio
- [ ] Generar reportes
- [ ] Optimizar queries lentas
- [ ] Documentar hallazgos

## 📊 Métricas de Éxito

| Métrica | Objetivo |
|---------|----------|
| Tiempo de respuesta queries | < 1 segundo |
| Integridad referencial | 100% |
| Cobertura de pruebas | > 80% |
| Documentación | Completa |
| Normalización | 3FN |

## 📚 Referencias

- Dataset: [Kaggle - Uber Ride Analytics](https://www.kaggle.com/datasets/yashdevladdha/uber-ride-analytics-dashboard/data)
- Documentación Oracle: [Oracle Database Documentation](https://docs.oracle.com/en/database/)
- Normalización: [Database Normalization](https://en.wikipedia.org/wiki/Database_normalization)

---

**📅 Última Actualización**: Noviembre 2025  
**👨‍💻 Estado**: 🟡 En Desarrollo - Estructura Completa
