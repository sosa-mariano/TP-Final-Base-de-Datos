-- =============================================================================
-- 00_reset.sql
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Vacía las 14 tablas para poder volver a cargar los datos (03_carga_datos.sql)
-- y repetir las pruebas. El esquema, los tipos, las restricciones y los
-- triggers siguen existiendo: solo se borran las filas.
--
-- Uso: ejecutar conectado a la base "sistema_justicia" con un usuario que sea
-- dueño de las tablas (usr_admin / postgres). Orden de ejecución habitual:
--     00_reset.sql  ->  03_carga_datos.sql
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- PASO 1: desactivar los triggers de usuario
-- -----------------------------------------------------------------------------
ALTER TABLE familiar               DISABLE TRIGGER USER;
ALTER TABLE duenioDomicilio        DISABLE TRIGGER USER;
ALTER TABLE acusado                DISABLE TRIGGER USER;
ALTER TABLE historialEstadoAcusado DISABLE TRIGGER USER;
ALTER TABLE condena                DISABLE TRIGGER USER;
ALTER TABLE modificacionCondena    DISABLE TRIGGER USER;

-- -----------------------------------------------------------------------------
-- PASO 2: vaciar las tablas, de la hija a la padre
-- (es el orden inverso al de carga del plan, sección 9.4)
-- -----------------------------------------------------------------------------
DELETE FROM modificacionCondena;      -- -> condena, unidadCarcelaria, domicilio
DELETE FROM condena;                  -- -> acusado, unidadCarcelaria, domicilio
DELETE FROM historialEstadoAcusado;   -- -> acusado
DELETE FROM acusado;                  -- -> persona, causaJudicial
DELETE FROM causaJudicial;            -- -> juez, secretario, fiscalia, secretaria
DELETE FROM unidadCarcelaria;         -- -> domicilio
DELETE FROM fiscalia;                 -- -> domicilio, persona
DELETE FROM secretario;               -- -> persona, secretaria
DELETE FROM secretaria;               -- -> domicilio, persona
DELETE FROM juez;                     -- -> persona
DELETE FROM duenioDomicilio;          -- -> persona, domicilio
DELETE FROM familiar;                 -- -> persona
DELETE FROM persona;                  -- -> domicilio
DELETE FROM domicilio;                -- sin dependencias

-- -----------------------------------------------------------------------------
-- PASO 3: reactivar los triggers de usuario
-- -----------------------------------------------------------------------------
ALTER TABLE familiar               ENABLE TRIGGER USER;
ALTER TABLE duenioDomicilio        ENABLE TRIGGER USER;
ALTER TABLE acusado                ENABLE TRIGGER USER;
ALTER TABLE historialEstadoAcusado ENABLE TRIGGER USER;
ALTER TABLE condena                ENABLE TRIGGER USER;
ALTER TABLE modificacionCondena    ENABLE TRIGGER USER;

COMMIT;

-- =============================================================================
-- VERIFICACIÓN (solo lectura; correr después del COMMIT)
-- =============================================================================

-- Las 14 tablas deben mostrar 0 filas.
SELECT 'domicilio' AS tabla, COUNT(*) AS filas FROM domicilio
UNION ALL SELECT 'persona',                COUNT(*) FROM persona
UNION ALL SELECT 'familiar',               COUNT(*) FROM familiar
UNION ALL SELECT 'duenioDomicilio',        COUNT(*) FROM duenioDomicilio
UNION ALL SELECT 'juez',                   COUNT(*) FROM juez
UNION ALL SELECT 'secretaria',             COUNT(*) FROM secretaria
UNION ALL SELECT 'secretario',             COUNT(*) FROM secretario
UNION ALL SELECT 'fiscalia',               COUNT(*) FROM fiscalia
UNION ALL SELECT 'unidadCarcelaria',       COUNT(*) FROM unidadCarcelaria
UNION ALL SELECT 'causaJudicial',          COUNT(*) FROM causaJudicial
UNION ALL SELECT 'acusado',                COUNT(*) FROM acusado
UNION ALL SELECT 'historialEstadoAcusado', COUNT(*) FROM historialEstadoAcusado
UNION ALL SELECT 'condena',                COUNT(*) FROM condena
UNION ALL SELECT 'modificacionCondena',    COUNT(*) FROM modificacionCondena;

-- Ningún trigger de usuario debe quedar desactivado:
-- tgenabled = 'O' significa activo; 'D' significa desactivado.
-- Esta consulta debe devolver 0 filas.
SELECT tgrelid::regclass AS tabla, tgname AS trigger, tgenabled
FROM pg_trigger
WHERE NOT tgisinternal
  AND tgenabled = 'D';
