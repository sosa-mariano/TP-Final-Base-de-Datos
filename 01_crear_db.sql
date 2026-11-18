
-- =============================================================================
-- 00_crear_db.sql  
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Equivale a hacer clic en pgAdmin 4:
--   Servers > PostgreSQL > Databases > Create > Database...
-- pero de forma reproducible, sin usar el asistente gráfico.
--
-- Valores usados (el resto queda por defecto):
--   * Nombre ........ sistema_justicia
--   * Owner ......... postgres
--   * Definition .... Encoding = UTF8
--   * Comment ....... descripción del sistema
-- =============================================================================


-- Pestaña "General": nombre y owner  |  Pestaña "Definition": solo Encoding
-- >>> PASO 1: seleccionar desde CREATE hasta el ";" y presionar F5 <<<
CREATE DATABASE sistema_justicia
    WITH OWNER = postgres
         ENCODING = 'UTF8';


-- Pestaña "General": campo Comment
-- >>> PASO 2: seleccionar desde COMMENT hasta el ";" y presionar F5 <<<
COMMENT ON DATABASE sistema_justicia IS
    'Sistema de Justicia: administración de causas judiciales, acusados, condenas y unidades carcelarias. TP Final de Base de Datos, UADER 2026.';

-- =============================================================================
-- T02 crear el ENUM "T_Nacionalidad"  
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Se crea el ENUM "T_Nacionalidad" con los siguientes valores:
-- ('Argentino', 'Paraguayo', 'Uruguayo', 'Brasilero', 'Chileno', 'Boliviano');
-- =============================================================================

CREATE TYPE T_Nacionalidad AS ENUM
('Argentino', 'Paraguayo', 'Uruguayo', 'Brasilero', 'Chileno', 'Boliviano');

-- =============================================================================
-- T03 crear el ENUM "T_EstadoCivil"  
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Se crea el ENUM "T_EstadoCivil" con los siguientes valores:
-- ('Soltero', 'Casado', 'Divorciado', 'Viudo');
-- =============================================================================

CREATE TYPE T_EstadoCivil AS ENUM
('Soltero', 'Casado', 'Divorciado', 'Viudo');

-- =============================================================================
-- T06 crear el ENUM "T_EstadoAcusado"  
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Se crea el ENUM "T_EstadoAcusado" con los siguientes valores:
-- ('Indagado', 'Procesado', 'Condenado', 'Sobreseido');
-- =============================================================================

CREATE TYPE T_EstadoAcusado AS ENUM
('Indagado', 'Procesado', 'Condenado', 'Sobreseido');

-- =============================================================================
-- T08 crear el ENUM "T_TipoModificacion"  
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Se crea el ENUM "T_TipoModificacion" con los siguientes valores:
-- ('Extension', 'Reduccion', 'Traslado');
-- =============================================================================

CREATE TYPE T_TipoModificacion AS ENUM
('Extension', 'Reduccion', 'Traslado');
