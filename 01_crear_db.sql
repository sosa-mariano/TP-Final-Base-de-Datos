
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

-- Se crea el ENUM "T_Nacionalidad" con los siguientes valores:
-- ('Argentino', 'Paraguayo', 'Uruguayo', 'Brasilero', 'Chileno', 'Boliviano');

CREATE TYPE T_Nacionalidad AS ENUM
('Argentino', 'Paraguayo', 'Uruguayo', 'Brasilero', 'Chileno', 'Boliviano');

-- Se crea el ENUM "T_EstadoCivil" con los siguientes valores:
-- ('Soltero', 'Casado', 'Divorciado', 'Viudo');

CREATE TYPE T_EstadoCivil AS ENUM
('Soltero', 'Casado', 'Divorciado', 'Viudo');

-- Se crea el ENUM "T_NivelEducacion" con los siguientes valores:
-- ('SinEscolarizar', 'Inicial', 'PrimarioIncompleto', 'PrimarioCompleto', 'SecundarioIncompleto', 'SecundarioCompleto', 'TerciarioIncompleto', 'TerciarioCompleto', 'UniversitarioIncompleto', 'UniversitarioCompleto');
CREATE TYPE T_NivelEducacion AS ENUM
('SinEscolarizar', 'Inicial', 'PrimarioIncompleto', 'PrimarioCompleto', 'SecundarioIncompleto', 'SecundarioCompleto', 'TerciarioIncompleto', 'TerciarioCompleto', 'UniversitarioIncompleto', 'UniversitarioCompleto');

-- Se crea el ENUM "T_Parentesco" con los siguientes valores:
-- ('Madre', 'Padre', 'Hermano', 'Hermana', 'Hijo', 'Hija');
CREATE TYPE T_Parentesco AS ENUM
('Madre', 'Padre', 'Hermano', 'Hermana', 'Hijo', 'Hija');

-- Se crea el ENUM "T_EstadoAcusado" con los siguientes valores:
-- ('Indagado', 'Procesado', 'Condenado', 'Sobreseido');

CREATE TYPE T_EstadoAcusado AS ENUM
('Indagado', 'Procesado', 'Condenado', 'Sobreseido');

-- Se crea el ENUM "T_Modalidad" con los siguientes valores:
-- ('Unidad', 'Domiciliaria');
CREATE TYPE T_Modalidad AS ENUM
('Unidad', 'Domiciliaria');

-- Se crea el ENUM "T_TipoModificacion" con los siguientes valores:
-- ('Extension', 'Reduccion', 'Traslado');

CREATE TYPE T_TipoModificacion AS ENUM
('Extension', 'Reduccion', 'Traslado');

---========= CREACION DE TABLAS =================

CREATE TABLE domicilio (
    id_domicilio  INTEGER,
    calle         VARCHAR(100) NOT NULL,
    numero        VARCHAR(10)  NOT NULL,
    piso          VARCHAR(10),
    departamento  VARCHAR(10),
    localidad     VARCHAR(100) NOT NULL,
    provincia     VARCHAR(50)  NOT NULL,
    codigo_postal VARCHAR(8)   NOT NULL,
    PRIMARY KEY (id_domicilio)
);

CREATE TABLE persona (
    dni                    INTEGER,
    nombres                VARCHAR(100)     NOT NULL,
    apellidos              VARCHAR(100)     NOT NULL,
    fecha_nacimiento       DATE             NOT NULL,
    nacionalidad           T_Nacionalidad   NOT NULL,
    estado_civil           T_EstadoCivil    NOT NULL,
    nivel_educacion        T_NivelEducacion NOT NULL,
    profesion              VARCHAR(100)     NOT NULL,
    id_domicilio_principal INTEGER,
    PRIMARY KEY (dni),
    FOREIGN KEY (id_domicilio_principal) REFERENCES domicilio(id_domicilio)
);

CREATE TABLE familiar (
    dni_persona   INTEGER NOT NULL,
    dni_familiar  INTEGER NOT NULL,
    parentesco    T_Parentesco NOT NULL,
    PRIMARY KEY (dni_persona, dni_familiar),
    FOREIGN KEY (dni_persona)  REFERENCES persona(dni),
    FOREIGN KEY (dni_familiar) REFERENCES persona(dni),
    CONSTRAINT ck_familiar_distintos CHECK (dni_persona <> dni_familiar)
);

CREATE TABLE duenioDomicilio (
id_duenio_domicilio INTEGER NOT NULL,
fecha_inicio DATE NOT NULL,
fecha_fin DATE,
dni INTEGER NOT NULL,
id_domicilio INTEGER NOT NULL,

PRIMARY KEY (id_duenio_domicilio),
FOREIGN KEY (dni) REFERENCES Persona(dni),
FOREIGN KEY (id_domicilio) REFERENCES Domicilio(id_domicilio),
CONSTRAINT ck_duenio_periodo CHECK (fecha_fin >= fecha_inicio)
);

-- Aca va Juez

CREATE TABLE secretaria (
id_secretaria INTEGER NOT NULL,
nombre VARCHAR(100) NOT NULL,
id_domicilio INTEGER NOT NULL,
dni_encargado INTEGER NOT NULL,

PRIMARY KEY (id_secretaria),
FOREIGN KEY (id_domicilio) REFERENCES Domicilio(id_domicilio),
FOREIGN KEY (dni_encargado) REFERENCES Persona(dni)
);

-- Aca va Secretario

CREATE TABLE fiscalia (
    id_fiscalia   INTEGER,
    nombre        VARCHAR(100) NOT NULL,
    id_domicilio  INTEGER      NOT NULL,
    dni_encargado INTEGER,
    PRIMARY KEY (id_fiscalia),
    FOREIGN KEY (id_domicilio)  REFERENCES domicilio(id_domicilio),
    FOREIGN KEY (dni_encargado) REFERENCES persona(dni)
);

CREATE TABLE unidadCarcelaria (
id_unidad INTEGER NOT NULL,
nombre VARCHAR(100) NOT NULL,
id_domicilio INTEGER NOT NULL,

PRIMARY KEY (id_unidad),
FOREIGN KEY (id_domicilio) REFERENCES Domicilio(id_domicilio)
);

-- Aca va CausaJudicial

-- Aca va Acusado

-- Aca va historialEstadoAcusado

-- Aca va Condena

-- Aca va modificacionCondena

--