# Respuesta al equipo de revisión

Rechazo por falta de información en *App Review Information*, no por un fallo de
la app. No citan ninguna guideline incumplida.

El texto de abajo va **en inglés** y se pega tal cual en la conversación de App
Store Connect. Los puntos 2 a 7 están respondidos; el 1 lo tienes que grabar tú
siguiendo el guion del final.

---

## Texto para pegar en App Store Connect

```
Thank you for the review. Below is the information requested. We have also added
it to the App Review Information notes for future submissions.

1. SCREEN RECORDING
A screen recording captured on a physical iPhone running the latest iOS is
attached. It starts from a fresh install and shows both permission prompts,
the main flow, and the alarm ringing while the device is in silent mode.

2. DEVICES AND OPERATING SYSTEMS TESTED
- iPhone 15 Pro Max, iOS 26.6 — physical device. Full manual testing, including
  the alarm ringing with the ring switch set to silent and with a Focus mode
  active.
- iPhone 17 and iPhone 17 Pro Max simulators, iOS 26.2 — UI, localisation and
  permission flows.
The app requires iOS 26.1 or later and is iPhone only.

3. PURPOSE AND TARGET AUDIENCE
The app sets a real alarm before the user's calendar events.

The problem it solves: calendar alerts are notifications, so they are silenced
when the iPhone is on silent or in a Focus mode, and the user misses the
meeting. This app instead schedules a genuine alarm through AlarmKit, which
rings above silent mode and Focus and presents a Live Activity with a countdown
on the Lock Screen, exactly like the built-in Clock app.

The value it provides: the user chooses how long before each event the alarm
rings, per calendar or per individual event, so an important meeting cannot be
missed because the phone was silenced.

Target audience: people who cannot afford to be late. Professionals with
back-to-back meetings, remote workers who keep the phone on silent, shift
workers, students, and anyone with medical appointments booked months ahead.

4. SETTING UP AND ACCESSING THE MAIN FEATURES
There is no account, no login and no credentials of any kind. Nothing is gated.

Steps to test:
a) Launch the app. It asks for two permissions: calendar access (to know when
   events start) and alarm permission (to ring above silent mode). Both are
   required for the app to do anything.
b) IMPORTANT: the app reads existing calendar events, it never creates them. On
   a device with no upcoming events the "Upcoming" list is legitimately empty.
   Before testing, please open the built-in Calendar app and create one or two
   events starting later today or tomorrow.
c) Reopen the app. Each event appears under "Upcoming" together with the exact
   time its alarm will ring.
d) Each row has a switch to turn that event's alarm on or off individually.
e) The "Calendars" tab enables or disables whole calendars and sets a different
   lead time for each one.
f) The "Settings" tab sets the default lead time (10 minutes by default), the
   snooze duration, and whether alarms apply only to events the user has
   accepted or to every event.
g) To see an alarm actually ring, create an event starting about 12 minutes from
   now and leave the default 10-minute lead time.

No sample files or demo accounts are needed.

5. EXTERNAL SERVICES, TOOLS OR PLATFORMS
None. The app uses no external services whatsoever.

It makes no network connections at all. There is no server, no backend, no
analytics, no advertising, no attribution, no AI service, no payment processing
and no third-party SDK or library. The binary does not even link the system
networking libraries (CFNetwork, Network.framework), which can be verified with
"otool -L" on the submitted binary.

It uses only Apple frameworks: EventKit (reading calendars), AlarmKit
(scheduling alarms), ActivityKit and WidgetKit (the Lock Screen Live Activity),
BackgroundTasks and SwiftUI.

Regarding Google and Microsoft: the app does NOT connect to Google or Microsoft
and implements no OAuth or sign-in. If the user has added those accounts in iOS
Settings > Apps > Calendar > Accounts, iOS itself syncs them and the app simply
reads what iOS already stores locally through EventKit, exactly as it does with
iCloud. On a review device without such accounts configured, only local and
iCloud calendars appear, which is the expected behaviour.

The complete source code is public and can be audited at
https://github.com/eljommys/alarm_on_calendar

6. REGIONAL DIFFERENCES
There are none. The app behaves identically in every region. There is no
region-gated content, no geolocation, no server-side configuration and no
remote content of any kind, since the app never connects to the internet.

It is localised in Spanish and English, and follows the device language. That is
the only difference a user can perceive, and it depends on the device setting
rather than on the region.

7. REGULATED INDUSTRY OR PROTECTED THIRD-PARTY MATERIAL
Not applicable. The app does not operate in a regulated industry and includes no
protected third-party material.

The names Google, Microsoft, Outlook and Exchange appear in the description and
in an in-app help screen purely descriptively, to explain that the app reads the
calendar accounts the user has already configured in iOS Settings. No third-party
logos, trademarks or assets are used, no affiliation or endorsement is claimed,
and the app does not connect to those services.
```

---

## Guion de la grabación (punto 1)

Apple exige **dispositivo físico** y que empiece por el lanzamiento de la app.
La clave es que salgan los dos diálogos de permiso, así que hay que grabar desde
una instalación limpia.

**Antes de grabar**

1. Borra la app del iPhone. Eso reinicia los permisos concedidos; si no, los
   diálogos no volverán a aparecer y la grabación quedaría incompleta.
2. Vuelve a instalarla desde TestFlight.
3. En la app Calendario de iOS crea dos o tres eventos con horas creíbles, y uno
   que empiece **dentro de unos 12 minutos** para que la alarma suene durante la
   grabación.
4. Pon el interruptor lateral en **silencio**. Es justo lo que demuestra el valor
   de la app.
5. Empieza a grabar con el Centro de Control.

**Qué mostrar, en este orden**

| Paso | Qué se ve |
| --- | --- |
| 1 | La pantalla de inicio y el toque sobre el icono de la app |
| 2 | La pantalla de bienvenida completa |
| 3 | «Permitir acceso» → el diálogo del sistema → conceder acceso total |
| 4 | «Permitir alarmas» → el diálogo del sistema → conceder |
| 5 | La pestaña Próximos con los eventos y la hora de cada alarma |
| 6 | Apagar el interruptor de un evento y volver a encenderlo |
| 7 | La pestaña Calendarios: apagar un calendario y cambiar su antelación |
| 8 | La pestaña Ajustes: cambiar el modo y la antelación general |
| 9 | Bloquear el iPhone y **esperar a que suene la alarma** |
| 10 | La alarma sonando en la pantalla de bloqueo, con el móvil en silencio |
| 11 | Pulsar «Posponer» y luego detenerla |

El paso 10 es el más importante de todos: es la función central de la app y lo
único que un revisor no puede deducir de una captura estática.

**Cómo enviarla**

La conversación de App Store Connect admite adjuntos. Si el vídeo pesa demasiado,
súbelo a un enlace accesible sin registro y pega la URL en la respuesta.

---

## Por qué ha pasado esto

El campo *App Review Information → Notes* estaba vacío o incompleto. Es la causa
habitual de este rechazo, y no tiene nada que ver con la calidad de la app.

Para las próximas versiones, las notas ampliadas ya están en
[`ficha.md`](ficha.md); pégalas en ese campo antes de enviar y este rechazo no se
repite.
