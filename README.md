# Waiwareminders

Aplicacion Flutter de recordatorios periodicos. La version actual es un MVP
local: permite crear tareas, guardarlas en el dispositivo, consultarlas en un
calendario y programar avisos sin depender de un servidor.

## Estado actual

La aplicacion ya permite:

- Crear recordatorios con titulo, descripcion, fecha y hora.
- Elegir una frecuencia de 2, 4, 6, 12 o 24 horas.
- Introducir una frecuencia personalizada en horas.
- Ver las tareas activas ordenadas por fecha.
- Marcar tareas como completadas.
- Editar y eliminar tareas.
- Consultar un calendario mensual con puntos en los dias que tienen tareas.
- Ver las tareas de un dia ordenadas por hora.
- Programar notificaciones locales periodicas.
- Mantener los datos al cerrar y volver a abrir la aplicacion.

La interfaz usa crema como color base, terracota como color de accion y un
tono oscuro para el contenido.

## Como ejecutar el proyecto

Requisitos:

- Flutter compatible con Dart `3.13.4` o superior dentro de la restriccion del
  proyecto.
- Un dispositivo Android o iOS, o un runner de escritorio configurado.
- En Windows, Flutter puede requerir Developer Mode para crear symlinks cuando
  se usan plugins.

Comandos habituales:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Para Android:

```bash
flutter run -d <device-id>
```

La app solicita permisos de notificaciones al inicializarse. En Android se
declaran `POST_NOTIFICATIONS` y `RECEIVE_BOOT_COMPLETED` en el manifest.

## Flujo de la aplicacion

La entrada es `lib/main.dart`:

1. Inicializa Flutter.
2. Inicializa `NotificationService`.
3. Ejecuta `ReminderApp`.

`ReminderApp` configura el tema y muestra `HomeScreen`. `HomeScreen` es el
coordinador actual del estado:

```text
HomeScreen
  |-- StorageService       carga y guarda recordatorios
  |-- NotificationService  cancela y programa avisos
  |-- AddReminderScreen    crea o edita
  |-- ReminderDetailScreen consulta, completa o elimina
  `-- CalendarScreen       muestra mes y tareas por dia
```

Al abrir la pantalla principal:

1. Se cargan los recordatorios desde el almacenamiento local.
2. Los recordatorios no completados vuelven a programar sus notificaciones.
3. La pestaña `Tareas` muestra los recordatorios pendientes.
4. La pestaña `Calendario` muestra el mes, los dias con tareas y el detalle del
   dia seleccionado.

## Modelo y almacenamiento

El modelo se encuentra en [lib/models/reminder.dart](lib/models/reminder.dart)
y contiene actualmente:

```text
id: int?
title: String
description: String
dateTime: DateTime
reminderInterval: Duration
completed: bool
```

`Reminder.toJson()` y `Reminder.fromJson()` definen el contrato de persistencia.
Los datos se guardan como una lista de cadenas JSON en `SharedPreferences`, bajo
la clave `reminders`, desde [lib/services/storage_service.dart](lib/services/storage_service.dart).

Para cambiar el formato persistido:

1. Modificar el modelo y sus metodos JSON.
2. Mantener compatibilidad con campos ausentes en `fromJson()`.
3. Añadir una migracion si cambia el significado de un campo existente.
4. Probar carga de datos antiguos antes de publicar la nueva version.

## Notificaciones actuales

[lib/services/notification_service.dart](lib/services/notification_service.dart)
usa `flutter_local_notifications` y `timezone`.

El comportamiento actual es:

- Si la fecha inicial ya paso, calcula la siguiente ocurrencia futura.
- Programa hasta 60 ocurrencias futuras por recordatorio.
- Al editar, completar o eliminar, cancela los avisos asociados.
- Al abrir la app, vuelve a llenar la ventana de ocurrencias futuras.
- Un recordatorio completado no vuelve a programarse.

Esto permite recordatorios periodicos mientras la app se vuelve a abrir
ocasionalmente para renovar la ventana. Todavia no existe un campo `deadline`,
por lo que la repeticion no se detiene en una fecha limite especifica.

## Estructura relevante

```text
lib/
  main.dart
  app/
    app.dart
    theme.dart
  models/
    reminder.dart
  screens/
    home_screen.dart
    calendar_screen.dart
    add_reminder_screen.dart
    reminder_detail_screen.dart
  widgets/
    reminder_card.dart
    reminder_form.dart
    empty_state.dart
  services/
    storage_service.dart
    notification_service.dart
  utils/
    date_utils.dart
```

`calendar_view.dart` existe como espacio para extraer la parte visual del
calendario. Actualmente la implementacion vive en `CalendarScreen`.

## Como conectar futuras implementaciones

### 1. Fecha limite

Agregar `DateTime? deadline` al modelo y al JSON. El formulario debe permitir
seleccionarla y `NotificationService.schedule()` debe dejar de generar
ocurrencias cuando `next` supere esa fecha.

La regla recomendada es:

```text
fecha inicial <= aviso < fecha limite
```

Tambien hay que decidir que ocurre cuando no se define fecha limite: mantener
la ventana renovable actual o usar una politica de retencion definida.

### 2. Separar estado y dominio

`HomeScreen` concentra actualmente carga, guardado, CRUD y notificaciones.
Cuando crezca la app, mover esas operaciones a un `ReminderController` o
`ChangeNotifier`/Riverpod notifier. Las pantallas deberian recibir estado y
acciones, no conocer los detalles de `SharedPreferences`.

El punto de migracion natural es:

```text
HomeScreen -> ReminderController -> StorageService
                                  -> NotificationService
```

### 3. Cambiar de SharedPreferences a una base de datos

Para filtros, busqueda, categorias o muchos recordatorios, reemplazar
`StorageService` por Hive, Isar o SQLite. Mantener la interfaz publica
`loadReminders()` y `saveReminders()` durante la migracion para no acoplar las
pantallas al motor elegido.

Antes de hacerlo, definir ids estables, version de esquema y migraciones.

### 4. Mejorar la agenda de notificaciones

El servicio actual programa una ventana fija de 60 avisos. Para una solucion
mas robusta se puede:

- Guardar un identificador de notificacion por ocurrencia.
- Reprogramar despues de entregar cada aviso.
- Usar una fecha limite.
- Manejar zonas horarias y cambios de hora de verano.
- Añadir acciones de notificacion como `Completar` y `Posponer`.
- Cubrir Android, iOS y escritorio con estrategias especificas por plataforma.

Los cambios deben centralizarse en `NotificationService`; el modelo no debe
importar clases de Flutter ni del plugin de notificaciones.

### 5. Sincronizacion y cuenta de usuario

La app no tiene backend ni autenticacion. Para sincronizar:

1. Crear un repositorio remoto separado de `StorageService`.
2. Añadir `createdAt`, `updatedAt` y una version del registro.
3. Definir conflictos entre cambios locales y remotos.
4. Mantener almacenamiento local como cache y soporte offline.
5. Sincronizar primero los datos, y programar notificaciones solo desde el
   estado local confirmado.

### 6. Evolucion del calendario

El calendario actual es mensual y muestra un unico nivel de detalle diario.
Las siguientes mejoras pueden conectarse desde `CalendarScreen` sin cambiar el
modelo base:

- Selector de mes y salto a hoy.
- Vista semanal o diaria.
- Filtros por completado, categoria o prioridad.
- Arrastrar para cambiar fecha y hora.
- Componente reutilizable en `widgets/calendar_view.dart`.

## Pruebas

El test actual comprueba que la aplicacion arranca y muestra el estado vacio.
Las siguientes pruebas son las mas importantes para crecer con seguridad:

- Serializacion y deserializacion de `Reminder`.
- Guardado y carga de `StorageService`.
- Calculo de la siguiente ocurrencia de una notificacion.
- Creacion y edicion desde el formulario.
- Cambio de completado y eliminacion.
- Seleccion de fechas y tareas en el calendario.

Ejecutar siempre antes de integrar cambios:

```bash
flutter analyze
flutter test
```

## Funciones pendientes

No forman parte de la implementacion actual y quedan preparadas para una
siguiente etapa:

- Fecha limite para detener los avisos.
- Categorias, etiquetas, prioridad y colores por tarea.
- Busqueda y filtros.
- Sincronizacion en la nube y autenticacion.
- Acciones desde la notificacion.
- Vista semanal/diaria y reordenacion mediante arrastre.
- Persistencia con una base de datos orientada a consultas.
