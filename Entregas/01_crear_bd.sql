
-- 1. CREACION DE TIPOS ENUM


CREATE TYPE T_Nacionalidad AS ENUM (
    'Argentino',
    'Paraguayo',
    'Uruguayo',
    'Brasilero',
    'Chileno',
    'Boliviano'
);

CREATE TYPE T_EstadoCivil AS ENUM (
    'Soltero',
    'Casado',
    'Divorciado',
    'Viudo'
);

CREATE TYPE T_NivelEducacion AS ENUM (
    'SinEscolarizar',
    'Inicial',
    'PrimarioIncompleto',
    'PrimarioCompleto',
    'SecundarioIncompleto',
    'SecundarioCompleto',
    'TerciarioIncompleto',
    'TerciarioCompleto',
    'UniversitarioIncompleto',
    'UniversitarioCompleto'
);

CREATE TYPE T_Parentesco AS ENUM (
    'Madre',
    'Padre',
    'Hermano',
    'Hermana',
    'Hijo',
    'Hija'
);

CREATE TYPE T_EstadoAcusado AS ENUM (
    'Indagado',
    'Procesado',
    'Condenado',
    'Sobreseido'
);

CREATE TYPE T_Modalidad AS ENUM (
    'Unidad',
    'Domiciliaria'
);

CREATE TYPE T_TipoModificacion AS ENUM (
    'Extension',
    'Reduccion',
    'Traslado'
);

-- 2. CREACION DE TABLAS

CREATE TABLE domicilio (
    id_domicilio INTEGER PRIMARY KEY,
    calle VARCHAR(100) NOT NULL,
    numero VARCHAR(10) NOT NULL,
    piso VARCHAR(10),
    departamento VARCHAR(10),
    localidad VARCHAR(100) NOT NULL,
    provincia VARCHAR(50) NOT NULL,
    codigo_postal VARCHAR(8) NOT NULL
);




CREATE TABLE persona (
    dni INTEGER PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    nacionalidad T_Nacionalidad NOT NULL,
    estado_civil T_EstadoCivil NOT NULL,
    nivel_educacion T_NivelEducacion NOT NULL,
    profesion VARCHAR(100) NOT NULL,
    id_domicilio_principal INTEGER,
    FOREIGN KEY (id_domicilio_principal)
        REFERENCES domicilio(id_domicilio)
);




CREATE TABLE familiar (
    dni_persona INTEGER,
    dni_familiar INTEGER,
    parentesco T_Parentesco NOT NULL,
    PRIMARY KEY (dni_persona, dni_familiar),
    FOREIGN KEY (dni_persona) REFERENCES persona(dni),
    FOREIGN KEY (dni_familiar) REFERENCES persona(dni)
);




CREATE TABLE duenioDomicilio (
    id_duenio_domicilio INTEGER PRIMARY KEY,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    dni INTEGER NOT NULL,
    id_domicilio INTEGER NOT NULL,
    FOREIGN KEY (dni) REFERENCES persona(dni),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio)
);




CREATE TABLE juez (
    dni INTEGER PRIMARY KEY,
    FOREIGN KEY (dni) REFERENCES persona(dni)
);



CREATE TABLE secretaria (
    id_secretaria INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_domicilio INTEGER NOT NULL,
    dni_encargado INTEGER,
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),
    FOREIGN KEY (dni_encargado) REFERENCES persona(dni)
);



CREATE TABLE secretario (
    dni INTEGER PRIMARY KEY,
    id_secretaria INTEGER NOT NULL,
    FOREIGN KEY (dni) REFERENCES persona(dni),
    FOREIGN KEY (id_secretaria) REFERENCES secretaria(id_secretaria)
);



CREATE TABLE fiscalia (
    id_fiscalia INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_domicilio INTEGER NOT NULL,
    dni_encargado INTEGER,
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio),
    FOREIGN KEY (dni_encargado) REFERENCES persona(dni)
);



CREATE TABLE causaJudicial (
    numero_registro INTEGER PRIMARY KEY,
    caratula VARCHAR(255) NOT NULL,
    fecha_alta DATE NOT NULL,
    fecha_resolucion DATE,
    dni_juez INTEGER NOT NULL,
    dni_secretario INTEGER NOT NULL,
    id_fiscalia INTEGER NOT NULL,
    id_secretaria INTEGER NOT NULL,
    FOREIGN KEY (dni_juez) REFERENCES juez(dni),
    FOREIGN KEY (dni_secretario) REFERENCES secretario(dni),
    FOREIGN KEY (id_fiscalia) REFERENCES fiscalia(id_fiscalia),
    FOREIGN KEY (id_secretaria) REFERENCES secretaria(id_secretaria)
);



CREATE TABLE acusado (
    id_acusado INTEGER PRIMARY KEY,
    fecha_resolucion DATE,
    dni INTEGER NOT NULL,
    numero_registro INTEGER NOT NULL,
    UNIQUE (dni, numero_registro),
    FOREIGN KEY (dni) REFERENCES persona(dni),
    FOREIGN KEY (numero_registro) REFERENCES causaJudicial(numero_registro)
);



CREATE TABLE historialEstadoAcusado (
    id_historial INTEGER PRIMARY KEY,
    estado T_EstadoAcusado NOT NULL,
    fecha_cambio DATE NOT NULL,
    id_acusado INTEGER NOT NULL,
    FOREIGN KEY (id_acusado) REFERENCES acusado(id_acusado)
);



CREATE TABLE unidadCarcelaria (
    id_unidad INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    id_domicilio INTEGER NOT NULL,
    UNIQUE (id_domicilio),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio)
);



CREATE TABLE condena (
    id_condena INTEGER PRIMARY KEY,
    modalidad T_Modalidad NOT NULL,
    duracion_meses SMALLINT NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_baja DATE,
    motivo_baja VARCHAR(255),
    id_acusado INTEGER NOT NULL,
    id_unidad INTEGER,
    id_domicilio INTEGER,
    FOREIGN KEY (id_acusado) REFERENCES acusado(id_acusado),
    FOREIGN KEY (id_unidad) REFERENCES unidadCarcelaria(id_unidad),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio)
);



CREATE TABLE modificacionCondena (
    id_modificacion INTEGER PRIMARY KEY,
    tipo T_TipoModificacion NOT NULL,
    fecha DATE NOT NULL,
    razon TEXT NOT NULL,
    duracion_nueva_meses SMALLINT NOT NULL,
    id_condena INTEGER NOT NULL,
    id_unidad INTEGER,
    id_domicilio INTEGER,
    FOREIGN KEY (id_condena) REFERENCES condena(id_condena),
    FOREIGN KEY (id_unidad) REFERENCES unidadCarcelaria(id_unidad),
    FOREIGN KEY (id_domicilio) REFERENCES domicilio(id_domicilio)
);

