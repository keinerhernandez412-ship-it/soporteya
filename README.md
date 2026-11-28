# SoporteYa · Mesa de ayuda de TI

Proyecto guía del programa ADSO (SENA, ficha 3230489). Los funcionarios de una empresa reportan fallas de tecnología y los técnicos las atienden con tiempos de respuesta medidos.

## Cómo ejecutarlo

### Con Docker (recomendado)

```bash
cp .env.example .env        # y cambie las claves
docker compose up --build
```

### En la máquina virtual, sin Docker

```bash
sudo -u postgres psql -c "CREATE DATABASE soporteya OWNER adso;"
export DB_PASSWORD=su_clave
export JWT_SECRETO=$(openssl rand -base64 48)
./mvnw spring-boot:run
```

Abra http://localhost:8080 · usuarios de prueba con la contraseña `Soporte2026`:

| Correo | Rol |
|---|---|
| laura.gomez@soporteya.co | Coordinadora |
| carlos.ruiz@soporteya.co | Técnico (Hardware, Impresoras) |
| diana.torres@soporteya.co | Técnica (Software, Accesos) |
| mateo.diaz@soporteya.co | Técnico (Red, Hardware) |
| ana.perez@soporteya.co | Solicitante |

## Equipo

| Integrante | Rol en Scrum | Módulo |
|---|---|---|
| (nombre) | Dueño del producto | Tickets |
| (nombre) | Scrum Master | Tablero técnico |
| (nombre) | Desarrollo | Administración |