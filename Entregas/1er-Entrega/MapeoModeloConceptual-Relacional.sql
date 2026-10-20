--NOTA
--Las tablas están ordenadas para que cada FK referencie una tabla ya definida. Los enums solo figuran como tipo de columna


VAR BASE RELATION domicilio (
  id_domicilio: INTEGER,
  calle: VARCHAR(100) NOT NULL,
  numero: VARCHAR(10) NOT NULL,
  piso: VARCHAR(10),
  departamento: VARCHAR(10),
  localidad: VARCHAR(100) NOT NULL,
  provincia: VARCHAR(50) NOT NULL,
  codigo_postal: VARCHAR(8) NOT NULL,
  PRIMARY KEY (id_domicilio)
 )

 VAR BASE RELATION persona (
  dni: INTEGER,
  nombres: VARCHAR(100) NOT NULL,
  apellidos: VARCHAR(100) NOT NULL,
  fecha_nacimiento: DATE NOT NULL,
  nacionalidad: T_Nacionalidad NOT NULL,
  estado_civil: T_EstadoCivil NOT NULL,
  nivel_educacion: T_NivelEducacion NOT NULL,
  profesion: VARCHAR(100) NOT NULL,
  id_domicilio_principal: INTEGER,
  PRIMARY KEY (dni),
  FOREIGN KEY (id_domicilio_principal) REFERENCES domicilio
 )


VAR BASE RELATION familiar (
  dni_persona: INTEGER,
  dni_familiar: INTEGER,
  parentesco: T_Parentesco NOT NULL,
  PRIMARY KEY (dni_persona, dni_familiar),
  FOREIGN KEY (dni_persona) REFERENCES persona,
  FOREIGN KEY (dni_familiar) REFERENCES persona
)

VAR BASE RELATION duenioDomicilio (
  id_duenio_domicilio: INTEGER,
  fecha_inicio: DATE NOT NULL,
  fecha_fin: DATE,
  dni: INTEGER NOT NULL,
  id_domicilio: INTEGER NOT NULL,
  PRIMARY KEY (id_duenio_domicilio),
  FOREIGN KEY (dni) REFERENCES persona,
  FOREIGN KEY (id_domicilio) REFERENCES domicilio
)

VAR BASE RELATION juez (
  dni: INTEGER,
  PRIMARY KEY (dni),
  FOREIGN KEY (dni) REFERENCES persona
)


VAR BASE RELATION secretaria (
  id_secretaria: INTEGER,
  nombre: VARCHAR(100) NOT NULL,
  id_domicilio: INTEGER NOT NULL,
  dni_encargado: INTEGER,
  PRIMARY KEY (id_secretaria),
  FOREIGN KEY (id_domicilio) REFERENCES domicilio,
  FOREIGN KEY (dni_encargado) REFERENCES persona
)

VAR BASE RELATION secretario (
  dni: INTEGER,
  id_secretaria: INTEGER NOT NULL,
  PRIMARY KEY (dni),
  FOREIGN KEY (dni) REFERENCES persona,
  FOREIGN KEY (id_secretaria) REFERENCES secretaria
)

VAR BASE RELATION fiscalia (
  id_fiscalia: INTEGER,
  nombre: VARCHAR(100) NOT NULL,
  id_domicilio: INTEGER NOT NULL,
  dni_encargado: INTEGER,
  PRIMARY KEY (id_fiscalia),
  FOREIGN KEY (id_domicilio) REFERENCES domicilio,
  FOREIGN KEY (dni_encargado) REFERENCES persona
)

VAR BASE RELATION causaJudicial (
  numero_registro: INTEGER,
  caratula: VARCHAR(255) NOT NULL,
  fecha_alta: DATE NOT NULL,
  fecha_resolucion: DATE,
  dni_juez: INTEGER NOT NULL,
  dni_secretario: INTEGER NOT NULL,
  id_fiscalia: INTEGER NOT NULL,
  id_secretaria: INTEGER NOT NULL,
  PRIMARY KEY (numero_registro),
  FOREIGN KEY (dni_juez) REFERENCES juez,
  FOREIGN KEY (dni_secretario) REFERENCES secretario,
  FOREIGN KEY (id_fiscalia) REFERENCES fiscalia,
  FOREIGN KEY (id_secretaria) REFERENCES secretaria )

VAR BASE RELATION acusado (
  id_acusado: INTEGER,
  fecha_resolucion: DATE,
  dni: INTEGER NOT NULL,
  numero_registro: INTEGER NOT NULL,
  PRIMARY KEY (id_acusado),
  UNIQUE (dni, numero_registro),
  FOREIGN KEY (dni) REFERENCES persona,
  FOREIGN KEY (numero_registro) REFERENCES causaJudicial 
)

VAR BASE RELATION historialEstadoAcusado (
  id_historial: INTEGER,
  estado: T_EstadoAcusado NOT NULL,
  fecha_cambio: DATE NOT NULL,
  id_acusado: INTEGER NOT NULL,
  PRIMARY KEY (id_historial),
  FOREIGN KEY (id_acusado) REFERENCES acusado
)

VAR BASE RELATION unidadCarcelaria (
  id_unidad: INTEGER,
  nombre: VARCHAR(100) NOT NULL,
  id_domicilio: INTEGER NOT NULL,
  PRIMARY KEY (id_unidad),
  UNIQUE (id_domicilio),
  FOREIGN KEY (id_domicilio) REFERENCES domicilio )

VAR BASE RELATION condena (
  id_condena: INTEGER,
  modalidad: T_Modalidad NOT NULL,
  duracion_meses: SMALLINT NOT NULL,
  fecha_inicio: DATE NOT NULL,
  fecha_fin: DATE NOT NULL,
  activa: BOOLEAN NOT NULL,
  fecha_baja: DATE,
  motivo_baja: VARCHAR(255),
  id_acusado: INTEGER NOT NULL,
  id_unidad: INTEGER,
  id_domicilio: INTEGER,
  PRIMARY KEY (id_condena),
  FOREIGN KEY (id_acusado) REFERENCES acusado,
  FOREIGN KEY (id_unidad) REFERENCES unidadCarcelaria,
  FOREIGN KEY (id_domicilio) REFERENCES domicilio
)

VAR BASE RELATION condena (
  id_condena: INTEGER,
  modalidad: T_Modalidad NOT NULL,
  duracion_meses: SMALLINT NOT NULL,
  fecha_inicio: DATE NOT NULL,
  fecha_fin: DATE NOT NULL,
  fecha_baja: DATE,
  motivo_baja: VARCHAR(255),
  id_acusado: INTEGER NOT NULL,
  id_unidad: INTEGER,
  id_domicilio: INTEGER,
  PRIMARY KEY (id_condena),
  FOREIGN KEY (id_acusado) REFERENCES acusado,
  FOREIGN KEY (id_unidad) REFERENCES unidadCarcelaria,
  FOREIGN KEY (id_domicilio) REFERENCES domicilio,
)


VAR BASE RELATION modificacionCondena (
  id_modificacion: INTEGER,
  tipo: T_TipoModificacion NOT NULL,
  fecha: DATE NOT NULL,
  razon: TEXT NOT NULL,
  duracion_nueva_meses: SMALLINT NOT NULL,
  id_condena: INTEGER NOT NULL,
  id_unidad: INTEGER,
  id_domicilio: INTEGER,
  PRIMARY KEY (id_modificacion),
  FOREIGN KEY (id_condena) REFERENCES condena,
  FOREIGN KEY (id_unidad) REFERENCES unidadCarcelaria,
  FOREIGN KEY (id_domicilio) REFERENCES domicilio,
)

ENUM T_Nacionalidad (Argentino, Paraguayo, Uruguayo, Brasilero, Chileno, Boliviano)

ENUM T_EstadoCivil (Soltero, Casado, Divorciado, Viudo)

ENUM T_NivelEducacion (SinEscolarizar, Inicial, PrimarioIncompleto, PrimarioCompleto, SecundarioIncompleto, SecundarioCompleto, TerciarioIncompleto, TerciarioCompleto, UniversitarionIncompleto, UniversitarioCompleto)

ENUM T_Parentesco (Madre, Padre, Hermano, Hermana, Hijo, Hija)

ENUM T_EstadoAcusado (Indagado, Procesado, Condenado, Sobreseido)

ENUM T_Modalidad (Unidad, Domiciliaria)

ENUM T_TipoModificacion (Extension, Reduccion, Traslado)

