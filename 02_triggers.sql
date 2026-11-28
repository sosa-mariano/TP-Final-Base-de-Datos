-- =============================================================================
-- 02_triggers.sql
-- Sistema de Justicia - TP Final de Base de Datos (UADER, 2026)
--
-- Triggers del sistema (se ejecuta despues de 01_crear_db.sql y antes de la
-- carga de datos, para que la carga pase por los mismos controles que el uso
-- diario).
-- =============================================================================


-- =============================================================================
-- 1. trg_validar_transicion_estado
-- =============================================================================

--Creacion de la funcion que dispara el trigger.
CREATE OR REPLACE FUNCTION fn_trg_validar_transicion_estado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_previo T_EstadoAcusado;
    v_fecha_previa  DATE;
BEGIN
    -- UPDATE y DELETE: el historial es inmodificable
    IF TG_OP IN ('UPDATE', 'DELETE') THEN
        RAISE EXCEPTION
            'El historial de estados es inmodificable: no se permite % sobre historialEstadoAcusado',
            TG_OP;
    END IF;

    -- INSERT: el estado vigente es el ultimo registro del acusado en la tabla
    SELECT h.estado, h.fecha_cambio
      INTO v_estado_previo, v_fecha_previa
      FROM historialEstadoAcusado h
     WHERE h.id_acusado = NEW.id_acusado
     ORDER BY h.fecha_cambio DESC, h.id_estado_acusado DESC
     LIMIT 1;

    -- Primer registro: debe ser Indagado
    IF NOT FOUND THEN
        IF NEW.estado <> 'Indagado' THEN
            RAISE EXCEPTION
                'El estado inicial del acusado % debe ser Indagado (se intento registrar %)',
                NEW.id_acusado, NEW.estado;
        END IF;
        RETURN NEW;
    END IF;

    -- Transiciones permitidas segun el estado vigente
    CASE v_estado_previo

        WHEN 'Indagado' THEN
            CASE NEW.estado
                WHEN 'Procesado' THEN
                    NULL;  -- transicion valida
                WHEN 'Indagado' THEN
                    RAISE EXCEPTION
                        'El estado no puede retroceder ni repetirse (acusado %: % -> %)',
                        NEW.id_acusado, v_estado_previo, NEW.estado;
                ELSE  -- Condenado / Sobreseido
                    RAISE EXCEPTION
                        'Transicion no permitida (acusado %: % -> %)',
                        NEW.id_acusado, v_estado_previo, NEW.estado;
            END CASE;

        WHEN 'Procesado' THEN
            CASE NEW.estado
                WHEN 'Condenado', 'Sobreseido' THEN
                    NULL;  -- transicion valida
                ELSE  -- Indagado / Procesado
                    RAISE EXCEPTION
                        'El estado no puede retroceder ni repetirse (acusado %: % -> %)',
                        NEW.id_acusado, v_estado_previo, NEW.estado;
            END CASE;

        WHEN 'Condenado', 'Sobreseido' THEN
            RAISE EXCEPTION
                'El acusado % ya esta resuelto (%): no se puede registrar el estado %',
                NEW.id_acusado, v_estado_previo, NEW.estado;

    END CASE;

    -- Transicion valida: queda controlar la cronologia
    IF NEW.fecha_cambio < v_fecha_previa THEN
        RAISE EXCEPTION
            'Fecha inconsistente: fecha_cambio (%) es anterior a la del registro previo (%) del acusado %',
            NEW.fecha_cambio, v_fecha_previa, NEW.id_acusado;
    END IF;

    RETURN NEW;
END;
$$;

--Declaracion del trigger sobre la tabla.
CREATE TRIGGER trg_validar_transicion_estado
    BEFORE INSERT OR UPDATE OR DELETE ON historialEstadoAcusado
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_validar_transicion_estado();

-- =============================================================================
-- 2. trg_cerrar_resolucion
-- =============================================================================
--Creacion de la funcion que dispara el trigger.
CREATE OR REPLACE FUNCTION fn_trg_cerrar_resolucion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_numero_registro INTEGER;
BEGIN
 	-- Indagado / Procesado: no son estados de resolucion, no se toca nada
    IF NEW.estado NOT IN ('Condenado', 'Sobreseido') THEN
        RETURN NULL;
    END IF;

    -- 1) Resolucion del acusado: queda con la fecha del estado final.
    --    Primero buscamos a que causa pertenece el acusado.
    SELECT numero_registro
      INTO v_numero_registro
      FROM acusado
     WHERE id_acusado = NEW.id_acusado;

    UPDATE acusado
       SET fecha_resolucion = NEW.fecha_cambio
     WHERE id_acusado = NEW.id_acusado;

    -- 2) Resolucion de la causa: solo si no quedan acusados sin resolver
    --    (contamos los acusados de la causa que todavia no tienen fecha)
    IF (SELECT COUNT(*)
          FROM acusado
         WHERE numero_registro = v_numero_registro
           AND fecha_resolucion IS NULL) = 0 THEN

        -- La causa se cierra con la fecha mas reciente de sus acusados
        UPDATE causaJudicial
           SET fecha_resolucion = (SELECT MAX(fecha_resolucion)
                                     FROM acusado
                                    WHERE numero_registro = v_numero_registro)
         WHERE numero_registro = v_numero_registro
           AND fecha_resolucion IS NULL;   -- no sobrescribe una resolucion previa
    END IF;

    -- En un trigger AFTER el valor retornado se ignora
    RETURN NULL;

END;
$$;

--Declaracion del trigger sobre la tabla.
CREATE TRIGGER trg_cerrar_resolucion
    AFTER INSERT ON historialEstadoAcusado
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_cerrar_resolucion();


-- =============================================================================
-- 3. trg_proteger_condena
-- =============================================================================
-- Creacion de la funcion que dispara el trigger.

CREATE OR REPLACE FUNCTION fn_trg_proteger_condena()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- DELETE: no se permite eliminar condenas
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'No se permite eliminar la condena %: debe registrarse su baja',
            OLD.id_condena;
    END IF;

    -- UPDATE: solo se admite registrar la baja (fecha_baja y motivo_baja)
    -- y conservar la fecha_fin original (y demas datos de la condena)
    IF TG_OP = 'UPDATE' THEN
        IF NEW.id_condena IS DISTINCT FROM OLD.id_condena
           OR NEW.modalidad IS DISTINCT FROM OLD.modalidad
           OR NEW.duracion_meses IS DISTINCT FROM OLD.duracion_meses
           OR NEW.fecha_inicio IS DISTINCT FROM OLD.fecha_inicio
           OR NEW.fecha_fin IS DISTINCT FROM OLD.fecha_fin
           OR NEW.id_acusado IS DISTINCT FROM OLD.id_acusado
           OR NEW.id_unidad IS DISTINCT FROM OLD.id_unidad
           OR NEW.id_domicilio IS DISTINCT FROM OLD.id_domicilio THEN
            RAISE EXCEPTION
                'La condena % solo admite su baja (fecha_baja y motivo_baja) y debe conservar su fecha de fin original (%)',
                OLD.id_condena, OLD.fecha_fin;
        END IF;

        -- Si ya tenia baja registrada, no se permite modificarla ni quitarla
        IF OLD.fecha_baja IS NOT NULL OR OLD.motivo_baja IS NOT NULL THEN
            IF NEW.fecha_baja IS DISTINCT FROM OLD.fecha_baja
               OR NEW.motivo_baja IS DISTINCT FROM OLD.motivo_baja THEN
                RAISE EXCEPTION
                    'La condena % ya tiene baja registrada y no puede modificarse',
                    OLD.id_condena;
            END IF;
        END IF;

        -- Respaldo de validaciones de baja completa y fecha de baja no anterior al inicio
        IF (NEW.fecha_baja IS NULL) <> (NEW.motivo_baja IS NULL) THEN
            RAISE EXCEPTION
                'La baja de la condena % debe informar fecha_baja y motivo_baja completos',
                OLD.id_condena;
        END IF;

        IF NEW.motivo_baja IS NOT NULL AND btrim(NEW.motivo_baja) = '' THEN
            RAISE EXCEPTION
                'El motivo_baja de la condena % no puede estar vacio',
                OLD.id_condena;
        END IF;

        IF NEW.fecha_baja IS NOT NULL AND NEW.fecha_baja < NEW.fecha_inicio THEN
            RAISE EXCEPTION
                'La fecha_baja (%) de la condena % no puede ser anterior a fecha_inicio (%)',
                NEW.fecha_baja, OLD.id_condena, NEW.fecha_inicio;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Declaracion del trigger sobre la tabla.
CREATE TRIGGER trg_proteger_condena
    BEFORE UPDATE OR DELETE ON condena
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_proteger_condena();

-- =============================================================================
-- 4. trg_validar_duenio_domicilio
-- =============================================================================
-- Creacion de la funcion que dispara el trigger.

CREATE OR REPLACE FUNCTION fn_trg_validar_duenio_domicilio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- DELETE: no se permite borrar periodos de titularidad
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION
            'No se permite eliminar el registro de titularidad % del domicilio %',
            OLD.id_duenio_domicilio, OLD.id_domicilio;
    END IF;

    -- UPDATE: no se permite reasignar periodos (ni cambiar id_duenio_domicilio,
    -- dni, id_domicilio ni fecha_inicio); solo se admite cerrar o ajustar fecha_fin
    IF TG_OP = 'UPDATE' THEN
        IF NEW.id_duenio_domicilio IS DISTINCT FROM OLD.id_duenio_domicilio
           OR NEW.dni IS DISTINCT FROM OLD.dni
           OR NEW.id_domicilio IS DISTINCT FROM OLD.id_domicilio
           OR NEW.fecha_inicio IS DISTINCT FROM OLD.fecha_inicio THEN
            RAISE EXCEPTION
                'No se permite reasignar ni modificar los datos base del periodo de titularidad %',
                OLD.id_duenio_domicilio;
        END IF;
    END IF;

    -- INSERT o UPDATE: validar que no haya un segundo duenio actual (fecha_fin IS NULL)
    -- ni periodos superpuestos en el mismo domicilio
    IF NEW.fecha_fin IS NULL THEN
        IF EXISTS (
            SELECT 1
              FROM duenioDomicilio d
             WHERE d.id_domicilio = NEW.id_domicilio
               AND d.fecha_fin IS NULL
               AND (TG_OP = 'INSERT' OR d.id_duenio_domicilio <> NEW.id_duenio_domicilio)
        ) THEN
            RAISE EXCEPTION
                'El domicilio % ya posee un duenio actual sin fecha de fin',
                NEW.id_domicilio;
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM duenioDomicilio d
         WHERE d.id_domicilio = NEW.id_domicilio
           AND (TG_OP = 'INSERT' OR d.id_duenio_domicilio <> NEW.id_duenio_domicilio)
           AND d.fecha_inicio <= COALESCE(NEW.fecha_fin, '9999-12-31'::date)
           AND NEW.fecha_inicio <= COALESCE(d.fecha_fin, '9999-12-31'::date)
    ) THEN
        RAISE EXCEPTION
            'El periodo [% .. %] se superpone con otro periodo existente en el domicilio %',
            NEW.fecha_inicio, COALESCE(NEW.fecha_fin::text, 'actual'), NEW.id_domicilio;
    END IF;

    RETURN NEW;
END;
$$;

-- Declaracion del trigger sobre la tabla.
CREATE TRIGGER trg_validar_duenio_domicilio
    BEFORE INSERT OR UPDATE OR DELETE ON duenioDomicilio
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_validar_duenio_domicilio();