
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

---========= CREACION DE ENUMS =================

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

CREATE TABLE juez (
    dni INTEGER NOT NULL,
    PRIMARY KEY (dni),
    FOREIGN KEY (dni) REFERENCES persona(dni)
);

CREATE TABLE secretaria (
	id_secretaria INTEGER NOT NULL,
	nombre VARCHAR(100) NOT NULL,
	id_domicilio INTEGER NOT NULL,
	dni_encargado INTEGER NOT NULL,
	PRIMARY KEY (id_secretaria),
	FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),
	FOREIGN KEY (dni_encargado) REFERENCES persona(dni)
);

CREATE TABLE secretario (
    dni INTEGER NOT NULL,
    id_secretaria INTEGER NOT NULL,
    PRIMARY KEY (dni),
    FOREIGN KEY (dni) REFERENCES persona(dni),
    FOREIGN KEY (id_secretaria) REFERENCES secretaria(id_secretaria)
);

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
	FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),
	CONSTRAINT uq_unidad_domicilio UNIQUE (id_domicilio)
);

CREATE TABLE causaJudicial (
	numero_registro INTEGER,
	caratula VARCHAR(255) NOT NULL,
	fecha_alta DATE NOT NULL,
	fecha_resolucion DATE,
	dni_juez INTEGER NOT NULL,
	dni_secretario INTEGER NOT NULL,
	id_fiscalia INTEGER NOT NULL,
	id_secretaria INTEGER NOT NULL,
	PRIMARY KEY (numero_registro),
	FOREIGN KEY (dni_juez) REFERENCES juez(dni),
	FOREIGN KEY (dni_secretario) REFERENCES secretario(dni),
	FOREIGN KEY (id_fiscalia) REFERENCES fiscalia(id_fiscalia),
	FOREIGN KEY (id_secretaria) REFERENCES secretaria(id_secretaria)
);

CREATE TABLE acusado (
	id_acusado INTEGER,
	fecha_resolucion DATE,
	dni INTEGER NOT NULL,
	numero_registro INTEGER NOT NULL,
	PRIMARY KEY (id_acusado),
	FOREIGN KEY (dni) REFERENCES persona(dni),
	FOREIGN KEY (numero_registro) REFERENCES causajudicial(numero_registro),
	CONSTRAINT uq_acusado_dni_causa UNIQUE (dni, numero_registro)
);

CREATE TABLE historialEstadoAcusado (
    id_estado_acusado INTEGER,
    estado T_EstadoAcusado NOT NULL,
	fecha_cambio DATE NOT NULL,
    id_acusado INTEGER NOT NULL,
    PRIMARY KEY (id_estado_acusado),
    FOREIGN KEY (id_acusado) REFERENCES acusado(id_acusado)
);

CREATE TABLE condena (
    id_condena     INTEGER,
    modalidad      T_Modalidad  NOT NULL,
    duracion_meses SMALLINT     NOT NULL,
    fecha_inicio   DATE         NOT NULL,
    fecha_fin      DATE         NOT NULL,
    fecha_baja     DATE,
    motivo_baja    VARCHAR(255),
    id_acusado     INTEGER      NOT NULL,
    id_unidad      INTEGER,
    id_domicilio   INTEGER,
    PRIMARY KEY (id_condena),
    FOREIGN KEY (id_acusado)   REFERENCES acusado(id_acusado),
    FOREIGN KEY (id_unidad)    REFERENCES unidadCarcelaria(id_unidad),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),

    -- La duracion debe ser positiva
    CONSTRAINT ck_condena_duracion CHECK (duracion_meses > 0),

    -- fecha_fin conserva el valor ORIGINAL: fecha_inicio + duracion_meses meses
    CONSTRAINT ck_condena_fecha_fin CHECK (
        fecha_fin = (fecha_inicio + duracion_meses * INTERVAL '1 month')::date
    ),

    -- La baja (libertad) lleva fecha y motivo juntos: ambos nulos o ambos informados
    CONSTRAINT ck_condena_baja_completa CHECK (
        (fecha_baja IS NULL) = (motivo_baja IS NULL)
    ),

    -- La baja, si existe, no puede ser anterior al inicio de la condena
    CONSTRAINT ck_condena_baja_fecha CHECK (
        fecha_baja IS NULL OR fecha_baja >= fecha_inicio
    ),

    -- Destino segun modalidad:
    --   Unidad       -> id_unidad informado e id_domicilio nulo
    --   Domiciliaria -> id_domicilio informado e id_unidad nulo
    CONSTRAINT ck_condena_destino CHECK (
        (modalidad = 'Unidad'       AND id_unidad    IS NOT NULL AND id_domicilio IS NULL)
        OR
        (modalidad = 'Domiciliaria' AND id_domicilio IS NOT NULL AND id_unidad    IS NULL)
    )
);

CREATE TABLE modificacionCondena (
    id_modificacion      INTEGER,
    tipo                 T_TipoModificacion NOT NULL,
    fecha                DATE               NOT NULL,
    razon                TEXT               NOT NULL,
    duracion_nueva_meses SMALLINT           NOT NULL,
    id_condena           INTEGER            NOT NULL,
    id_unidad            INTEGER,
    id_domicilio         INTEGER,
    PRIMARY KEY (id_modificacion),
    FOREIGN KEY (id_condena)   REFERENCES condena(id_condena),
    FOREIGN KEY (id_unidad)    REFERENCES unidadCarcelaria(id_unidad),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),

    -- La duracion vigente tras la modificacion debe ser positiva
    CONSTRAINT ck_modif_duracion CHECK (duracion_nueva_meses > 0),

    -- La razon no puede ser vacia ni contener solo espacios
    CONSTRAINT ck_modif_razon CHECK (btrim(razon) <> ''),

    -- Destino segun el tipo:
    --   Extension / Reduccion -> id_unidad e id_domicilio nulos
    --   Traslado              -> exactamente uno de los dos informado
	CONSTRAINT ck_modif_destino CHECK (
		(tipo IN ('Extension', 'Reduccion')
			AND id_unidad IS NULL AND id_domicilio IS NULL)
		OR
		(tipo = 'Traslado' AND id_unidad    IS NOT NULL AND id_domicilio IS NULL)
		OR
		(tipo = 'Traslado' AND id_domicilio IS NOT NULL AND id_unidad    IS NULL)
	)
);