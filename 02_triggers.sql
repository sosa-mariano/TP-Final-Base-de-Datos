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
-- 3. trg_validar_acusado
-- =============================================================================

--Creacion de la funcion que dispara el trigger.
CREATE OR REPLACE FUNCTION fn_trg_validar_acusado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_dni_juez        INTEGER;
    v_dni_secretario  INTEGER;
    v_fecha_res       DATE;
    v_id_estado       INTEGER;
BEGIN
    -- Obtenemos juez, secretario y fecha de resolucion de la causa asociada
    SELECT c.dni_juez, c.dni_secretario, c.fecha_resolucion
      INTO v_dni_juez, v_dni_secretario, v_fecha_res
      FROM causaJudicial c
     WHERE c.numero_registro = NEW.numero_registro;

    -- 1) Validacion de roles: el juez y el secretario no pueden ser acusados en su causa
    IF NEW.dni = v_dni_juez THEN
        RAISE EXCEPTION
            'El juez (DNI %) no puede ser acusado en la causa %',
            NEW.dni, NEW.numero_registro;
    END IF;

    IF NEW.dni = v_dni_secretario THEN
        RAISE EXCEPTION
            'El secretario (DNI %) no puede ser acusado en la causa %',
            NEW.dni, NEW.numero_registro;
    END IF;

    -- 2) Regla del plan (9.6): no se admiten nuevos acusados en una causa ya resuelta.
    --    En UPDATE solo se controla si se cambia la causa o el DNI, para permitir
    --    que trg_cerrar_resolucion actualice fecha_resolucion sin bloqueos.
    IF v_fecha_res IS NOT NULL
       AND (TG_OP = 'INSERT' OR NEW.numero_registro <> OLD.numero_registro OR NEW.dni <> OLD.dni) THEN
        RAISE EXCEPTION
            'La causa % ya esta resuelta (%): no se admiten nuevos acusados',
            NEW.numero_registro, v_fecha_res;
    END IF;

    -- 3) Alta de acusado: registrar estado inicial Indagado en historialEstadoAcusado
    IF TG_OP = 'INSERT' THEN
        SELECT COALESCE(MAX(id_estado_acusado), 0) + 1
          INTO v_id_estado
          FROM historialEstadoAcusado;

        -- Nota: cambiar CURRENT_DATE por c.fecha_alta si cargan causas con fechas pasadas
        INSERT INTO historialEstadoAcusado (id_estado_acusado, estado, fecha_cambio, id_acusado)
        VALUES (v_id_estado, 'Indagado', CURRENT_DATE, NEW.id_acusado);
    END IF;

    -- En un trigger AFTER el valor retornado se ignora
    RETURN NULL;
END;
$$;

--Declaracion del trigger sobre la tabla.
CREATE TRIGGER trg_validar_acusado
    AFTER INSERT OR UPDATE ON acusado
    FOR EACH ROW
    EXECUTE FUNCTION fn_trg_validar_acusado();