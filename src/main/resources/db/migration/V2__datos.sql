-- SoporteYa · V2 · datos de prueba
-- Contraseña de todos los usuarios: Soporte2026 (guardada como hash BCrypt, nunca en texto plano)

insert into area (nombre) values ('Contabilidad'), ('Talento Humano'), ('Comercial'), ('Tecnología');

insert into categoria (nombre, descripcion) values
    ('Hardware', 'Computadores, pantallas, teclados y otros equipos'),
    ('Software', 'Programas, instalaciones y actualizaciones'),
    ('Red e internet', 'Conexión, wifi, cableado y VPN'),
    ('Impresoras', 'Impresión, escáner y tóner'),
    ('Accesos y contraseñas', 'Usuarios bloqueados, permisos y correo');

insert into usuario (nombre_completo, email, password, rol, area_id)
select v.nombre, v.email, '$2a$10$xnr1kIDQJXIZEU06EKYrzeE/GT3gRVZP6RQ/L/Je1b9w.9xc0kxtG', v.rol, a.id
from (values
    ('Laura Gómez',    'laura.gomez@soporteya.co',    'COORDINADOR', 'Tecnología'),
    ('Carlos Ruiz',    'carlos.ruiz@soporteya.co',    'TECNICO',     'Tecnología'),
    ('Diana Torres',   'diana.torres@soporteya.co',   'TECNICO',     'Tecnología'),
    ('Mateo Díaz',     'mateo.diaz@soporteya.co',     'TECNICO',     'Tecnología'),
    ('Ana Pérez',      'ana.perez@soporteya.co',      'SOLICITANTE', 'Contabilidad'),
    ('Jorge Herrera',  'jorge.herrera@soporteya.co',  'SOLICITANTE', 'Comercial'),
    ('Paola Martínez', 'paola.martinez@soporteya.co', 'SOLICITANTE', 'Talento Humano')
) as v (nombre, email, rol, area)
join area a on a.nombre = v.area;

insert into usuario_categoria (usuario_id, categoria_id)
select u.id, c.id
from (values
    ('carlos.ruiz@soporteya.co', 'Hardware'), ('carlos.ruiz@soporteya.co', 'Impresoras'),
    ('diana.torres@soporteya.co', 'Software'), ('diana.torres@soporteya.co', 'Accesos y contraseñas'),
    ('mateo.diaz@soporteya.co', 'Red e internet'), ('mateo.diaz@soporteya.co', 'Hardware')
) as v (email, categoria)
join usuario u on u.email = v.email
join categoria c on c.nombre = v.categoria;

-- Tickets en distintos estados. Las horas son relativas al momento en que corre la migración.
-- La fecha límite = creación + horas de la prioridad (BAJA 72, MEDIA 24, ALTA 8, CRITICA 4).
insert into ticket (asunto, descripcion, prioridad, estado, fecha_creacion, fecha_limite, fecha_resolucion,
                    solicitante_id, tecnico_id, categoria_id, version)
select v.asunto, v.descripcion, v.prioridad, v.estado,
       now() - make_interval(hours => v.hace),
       now() - make_interval(hours => v.hace) + make_interval(hours => v.limite),
       case when v.resuelto_en is null then null else now() - make_interval(hours => v.hace) + make_interval(hours => v.resuelto_en) end,
       s.id, t.id, c.id, 0
from (values
    (1, 'El computador no enciende', 'Desde esta mañana el equipo de escritorio no prende. La luz del botón no se enciende.',
        'ALTA', 'ABIERTO', 2, 8, null, 'ana.perez@soporteya.co', null, 'Hardware'),
    (2, 'No puedo entrar al sistema contable', 'Dice que mi usuario está bloqueado. Tengo que cerrar el mes hoy.',
        'CRITICA', 'EN_CURSO', 1, 4, null, 'ana.perez@soporteya.co', 'diana.torres@soporteya.co', 'Accesos y contraseñas'),
    (3, 'La impresora del segundo piso imprime manchado', 'Las hojas salen con rayas negras a un lado.',
        'BAJA', 'ABIERTO', 30, 72, null, 'paola.martinez@soporteya.co', null, 'Impresoras'),
    (4, 'Internet lento en la oficina comercial', 'Las videollamadas con clientes se cortan desde ayer.',
        'MEDIA', 'RESUELTO', 20, 24, 6, 'jorge.herrera@soporteya.co', 'mateo.diaz@soporteya.co', 'Red e internet'),
    (5, 'Instalar el antivirus en el portátil nuevo', 'Me entregaron un portátil y no tiene antivirus.',
        'MEDIA', 'CERRADO', 40, 24, 5, 'jorge.herrera@soporteya.co', 'diana.torres@soporteya.co', 'Software'),
    (6, 'El correo no sincroniza en el celular', 'En el computador llegan los correos, pero en el celular no.',
        'BAJA', 'ABIERTO', 5, 72, null, 'paola.martinez@soporteya.co', null, 'Software'),
    (7, 'La pantalla se ve amarilla', 'El monitor muestra todo con un tono amarillo desde que lo movieron.',
        'MEDIA', 'CERRADO', 50, 24, 30, 'paola.martinez@soporteya.co', 'carlos.ruiz@soporteya.co', 'Hardware'),
    (8, 'No funciona la VPN desde la casa', 'Al conectarme desde la casa sale error de autenticación.',
        'ALTA', 'EN_CURSO', 12, 8, null, 'jorge.herrera@soporteya.co', 'mateo.diaz@soporteya.co', 'Red e internet')
) as v (n, asunto, descripcion, prioridad, estado, hace, limite, resuelto_en, solicitante, tecnico, categoria)
join usuario s on s.email = v.solicitante
left join usuario t on t.email = v.tecnico
join categoria c on c.nombre = v.categoria
order by v.n;   -- los id quedan en este orden: SY-00001, SY-00002…

-- El historial de cada ticket con técnico (lo que antes hacía Ticket.cambiarEstado)
insert into comentario (texto, fecha, interno, autor_id, ticket_id)
select 'Estado: ABIERTO → EN_CURSO. Tomado por ' || u.nombre_completo, t.fecha_creacion + interval '20 minutes', false, u.id, t.id
from ticket t join usuario u on u.id = t.tecnico_id;

insert into comentario (texto, fecha, interno, autor_id, ticket_id)
select 'Estado: EN_CURSO → RESUELTO. Solución aplicada y probada con el usuario', t.fecha_resolucion, false, u.id, t.id
from ticket t join usuario u on u.id = t.tecnico_id
where t.fecha_resolucion is not null;

insert into comentario (texto, fecha, interno, autor_id, ticket_id)
select 'Estado: RESUELTO → CERRADO. Confirmado por el solicitante', t.fecha_resolucion + interval '1 hour', false, t.solicitante_id, t.id
from ticket t
where t.estado = 'CERRADO';

insert into comentario (texto, fecha, interno, autor_id, ticket_id)
select 'Revisar si el bloqueo viene del directorio activo o del sistema contable', t.fecha_creacion + interval '30 minutes', true, t.tecnico_id, t.id
from ticket t
where t.asunto = 'No puedo entrar al sistema contable';