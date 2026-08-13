# Ficha de App Store — Alarma Agenda

Todos los campos verificados contra los límites de App Store Connect con
`AppStore/comprobar-limites.py`.

---

## Nombre  · límite 30

```
Alarma Agenda
```

Alternativa con más peso para búsquedas, por si prefieres priorizar ASO sobre
marca (cabe igual):

```
Alarma Agenda: Calendario
```

---

## Subtítulo · límite 30

```
Alarma real antes de cada cita
```

---

## Texto promocional · límite 170

Se puede cambiar sin pasar por revisión, así que sirve para anunciar novedades.

```
Los avisos del calendario no suenan si llevas el móvil en silencio. Esta app pone una alarma de verdad antes de cada evento, y la activas o la quitas evento a evento.
```

---

## Palabras clave · límite 100

Separadas por comas y **sin espacios** después de la coma: los espacios cuentan
como caracteres y se desperdician. No repitas aquí palabras que ya estén en el
nombre o el subtítulo, porque Apple ya las indexa.

```
despertador,eventos,reunion,cita,aviso,recordatorio,silencio,concentracion,horario,trabajo,sonar
```

---

## Descripción · límite 4000

```
No es un recordatorio más. Es una alarma de verdad.

Los avisos del calendario son notificaciones: si tienes el iPhone en silencio o en modo Concentración, no te enteras. Y te pierdes la reunión.

Alarma Agenda programa una alarma real antes de cada evento. De las que suenan como el despertador, aunque el móvil esté en silencio, y aparecen en la pantalla de bloqueo con su cuenta atrás.


TÚ DECIDES CUÁNDO SUENA

• Elige la antelación: 5, 10, 30 minutos, una hora… lo que necesites.
• Dos modos: alarma solo en los eventos que has confirmado, o en todos, confirmados y sin confirmar.
• Una antelación distinta para cada calendario: 15 minutos para Trabajo, 5 para Personal.
• Posponer, igual que en el despertador.


CONTROL EVENTO A EVENTO

Cada evento de la lista lleva su interruptor. Pon alarma a esa reunión que aún no has confirmado, o quítala del cumpleaños que ya te sabes. Tu decisión manda sobre cualquier regla automática.

Y si es una reunión que se repite cada semana, puedes silenciar solo la del jueves sin tocar las demás.


TUS TRES CALENDARIOS, EN UN SITIO

Funciona con el calendario de iCloud y también con Google y con Microsoft (Outlook, Exchange y Microsoft 365).

No hace falta iniciar sesión en ningún sitio: si ya tienes esas cuentas añadidas en los Ajustes de tu iPhone, la app lee lo que el teléfono sincroniza. Y si no las tienes, dentro de la app hay una guía paso a paso que te acompaña.


PRIVACIDAD QUE PUEDES COMPROBAR

La app no tiene servidor. No se conecta a internet. Ni siquiera enlaza las bibliotecas de red del sistema, así que técnicamente no puede enviar nada a ninguna parte.

Tus eventos se leen y se procesan dentro del iPhone y no salen de él. Sin cuentas, sin registro, sin publicidad, sin analítica, sin seguimiento y sin librerías de terceros.

No tienes que fiarte de nuestra palabra: el código es público y cualquiera puede auditarlo.


PENSADA PARA QUIEN NO PUEDE LLEGAR TARDE

• Reuniones de trabajo que empiezan en punto.
• Citas médicas con meses de espera.
• Clases, entrenamientos y turnos.
• Videollamadas cuando trabajas desde casa con el móvil en silencio.
• Recogidas del colegio.


REQUISITOS

Requiere iOS 26.1 o posterior. La app usa AlarmKit, la tecnología de alarmas que Apple presentó con iOS 26 y que es lo único que permite a una app que no sea el Reloj sonar por encima del silencio y de los modos de Concentración.

La primera vez te pedirá dos permisos: acceso al calendario, para saber cuándo empiezan tus eventos, y permiso de alarmas, para poder avisarte aunque el teléfono esté en silencio.
```

---

## Enlaces

| Campo en App Store Connect | URL |
| --- | --- |
| Support URL (obligatorio) | `https://github.com/eljommys/alarm_on_calendar` |
| Privacy Policy URL (obligatorio) | `https://eljommys.github.io/alarm_on_calendar/privacy.html` |
| Marketing URL (opcional) | `https://eljommys.github.io/alarm_on_calendar/` |

---

## Etiqueta de privacidad (App Privacy)

Responde en App Store Connect: **«No, no recopilamos datos de esta app»**.

Es literalmente cierto y coherente con `App/PrivacyInfo.xcprivacy`, que declara
`NSPrivacyTracking = false`, ningún tipo de dato recogido y solo el motivo
`CA92.1` por el uso de `UserDefaults` para guardar los ajustes.

---

## Categorías sugeridas

- **Principal**: Productividad
- **Secundaria**: Utilidades

---

## Notas para el revisor (App Review Information)

```
La app programa alarmas con AlarmKit antes de los eventos del calendario del usuario.

CÓMO PROBARLA
1. Conceda los dos permisos que pide al abrirla (calendario y alarmas).
2. Cree un evento en la app Calendario de iOS que empiece dentro de unos 15 minutos.
3. Abra la app: el evento aparecerá en «Próximos» con la hora a la que sonará la alarma.
4. La antelación se ajusta en la pestaña Ajustes; por defecto son 10 minutos.

No hace falta cuenta ni credenciales: no hay inicio de sesión.

SOBRE GOOGLE Y MICROSOFT
La app no se conecta a Google ni a Microsoft y no implementa OAuth. Lee los
calendarios mediante EventKit, así que muestra las cuentas que el propio iOS ya
sincroniza desde Ajustes. En un dispositivo sin esas cuentas configuradas solo se
verán los calendarios locales y los de iCloud, lo cual es el comportamiento esperado.

PRIVACIDAD
La app no realiza ninguna conexión de red. El binario no enlaza CFNetwork ni
Network.framework y no incluye dependencias de terceros.
```

---
---

# App Store listing (en-US)

## Name · límite 30

```
Calendar Alarm
```

Alternativa con más peso para búsquedas:

```
Calendar Alarm: Real Alarms
```

---

## Subtitle · límite 30

```
Real alarms for your calendar
```

---

## Promotional text · límite 170

```
Calendar alerts stay quiet when your phone is on silent. This app sets a real alarm before each event, and you switch it on or off event by event.
```

---

## Keywords · límite 100

```
clock,event,meeting,appointment,reminder,silent,focus,schedule,work,ring,wake,agenda
```

---

## Description · límite 4000

```
Not another reminder. A real alarm.

Calendar alerts are notifications: if your iPhone is on silent or in a Focus mode, you simply don't hear them. And you miss the meeting.

Calendar Alarm schedules a real alarm before each event. The kind that rings like your morning alarm, even on silent, and shows up on the Lock Screen with its own countdown.


YOU DECIDE WHEN IT RINGS

• Choose the lead time: 5, 10, 30 minutes, an hour… whatever you need.
• Two modes: an alarm only on events you accepted, or on all of them, accepted or not.
• A different lead time for each calendar: 15 minutes for Work, 5 for Personal.
• Snooze, just like your morning alarm.


CONTROL EVENT BY EVENT

Every event in the list has its own switch. Set an alarm on that meeting you haven't confirmed yet, or drop the one on a birthday you already remember. Your decision overrides every automatic rule.

And for a meeting that repeats weekly, you can silence just Thursday's without touching the rest.


YOUR THREE CALENDARS, IN ONE PLACE

Works with your iCloud calendar, and with Google and Microsoft too (Outlook, Exchange and Microsoft 365).

There is no sign-in anywhere: if those accounts are already added in your iPhone's Settings, the app reads what your phone syncs. And if they aren't, the app includes a step-by-step guide that walks you through it.


PRIVACY YOU CAN VERIFY

The app has no server. It never connects to the internet. It doesn't even link the system networking libraries, so technically it cannot send anything anywhere.

Your events are read and processed inside your iPhone and never leave it. No accounts, no sign-up, no ads, no analytics, no tracking, no third-party libraries.

You don't have to take our word for it: the source code is public and anyone can audit it.


BUILT FOR PEOPLE WHO CAN'T BE LATE

• Work meetings that start on the hour.
• Doctor's appointments booked months ahead.
• Classes, training sessions and shifts.
• Video calls when you work from home with your phone on silent.
• School pickup.


REQUIREMENTS

Requires iOS 26.1 or later. The app uses AlarmKit, the alarm technology Apple introduced with iOS 26 and the only thing that lets an app other than Clock ring above silent mode and Focus.

The first time you open it, it asks for two permissions: calendar access, to know when your events start, and alarm permission, so it can reach you even with the phone on silent.
```

---

## Notes for App Review (en-US)

```
The app schedules alarms with AlarmKit before the user's calendar events.

HOW TO TEST
1. Grant the two permissions requested on launch (calendar and alarms).
2. Create an event in the iOS Calendar app starting about 15 minutes from now.
3. Open the app: the event appears under "Upcoming" with the time its alarm will ring.
4. The lead time is configurable in the Settings tab; the default is 10 minutes.

No account or credentials are needed: there is no sign-in.

ABOUT GOOGLE AND MICROSOFT
The app does not connect to Google or Microsoft and implements no OAuth. It reads
calendars through EventKit, so it shows whichever accounts iOS itself already syncs
from Settings. On a device without those accounts configured, only local and iCloud
calendars appear, which is the expected behaviour.

PRIVACY
The app makes no network requests. The binary links neither CFNetwork nor
Network.framework and includes no third-party dependencies.
```
