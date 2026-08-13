# Alarma en Calendario

Una alarma **de verdad** antes de cada evento de tu calendario: de las que suenan
aunque el iPhone esté en silencio o en modo Concentración, con la barra de cuenta
atrás en la pantalla de bloqueo.

Los avisos del calendario son notificaciones. Si tienes el timbre bajado, no te
enteras. Esta app cubre ese hueco.

> Requiere **iOS 26.1** o posterior · Solo iPhone

---

## Qué hace

- Programa una alarma antes de cada evento, con la antelación que elijas.
- **Dos modos**: alarma solo en los eventos que has confirmado (tu RSVP es
  «Aceptado»), o en todos, confirmados y sin confirmar.
- **Interruptor por evento** para activar o quitar la alarma a placer. La decisión
  manual manda sobre las reglas automáticas.
- **Antelación por calendario**: 15 minutos en Trabajo, 5 en Personal.
- Posponer, como en el despertador.
- Funciona con **iCloud, Google y Microsoft** a la vez.

## Privacidad

La app **no tiene servidor y no se conecta a internet**. No es solo una promesa:
el binario ni siquiera enlaza las bibliotecas de red del sistema.

```bash
otool -L AlarmOnCalendar | grep -iE "CFNetwork|Network.framework"   # sin resultados
```

Sin OAuth, sin cuentas, sin analítica, sin dependencias de terceros. La etiqueta
de privacidad de la App Store es «No se recopilan datos».

[Política de privacidad completa](https://eljommys.github.io/alarm_on_calendar/privacy.html)

### Cómo llegan Google y Microsoft sin red

El usuario añade esas cuentas en *Ajustes de iOS → Apps → Calendario → Cuentas*
(Google entra por CalDAV, Microsoft por Exchange). iOS las sincroniza y EventKit
las expone **todas igual**. La app se limita a leer lo que el iPhone ya tiene
guardado en local, así que nunca abre un socket. La propia app incluye una guía
que acompaña al usuario en ese proceso.

## Arquitectura

```
Shared/     Lógica pura: no importa EventKit ni AlarmKit, así que se prueba
            sin simulador ni permisos.
  EventSnapshot     Copia inmutable de una ocurrencia concreta
  EventFilter       Decide qué eventos llevan alarma, y por qué no los demás
  SyncEngine        Reconcilia alarmas deseadas contra las realmente programadas
  AlarmIDFactory    Identificadores deterministas por contenido
  AlarmSettings     Preferencias, con decodificación tolerante

App/        CalendarStore traduce EKEvent → EventSnapshot
            AlarmKitScheduler adapta AlarmScheduling → AlarmKit
            Interfaz SwiftUI

Widget/     Live Activity de la alarma (pantalla de bloqueo y Dynamic Island)
```

Tres decisiones que explican el resto del código:

**Identificadores por contenido.** El UUID de una alarma resume todo lo que la
define: evento, ocurrencia, hora de disparo, título y minutos de posponer. Así
cualquier cambio relevante produce un identificador distinto y `SyncEngine`, que
es un simple diff de conjuntos, retira la vieja y pone la nueva. Si dependiera
solo del evento, cambiar la antelación de 10 a 30 minutos dejaría la alarma
sonando a la hora antigua.

**La fecha de la ocurrencia es imprescindible.** En EventKit todas las
repeticiones de una serie comparten `eventIdentifier`; sin la fecha, las 52
reuniones semanales colapsarían en una sola alarma.

**El tope de alarmas no está documentado.** `AlarmKit` expone
`maximumLimitReached` pero Apple no dice cuántas admite. El motor programa de la
más cercana a la más lejana y trata el tope como caso normal, así que se comporta
bien sea cual sea el número real.

## Desarrollo

El `.xcodeproj` **se genera** y no se versiona.

```bash
brew install xcodegen
xcodegen generate
```

Compilar y pasar los tests:

```bash
xcodebuild -project AlarmOnCalendar.xcodeproj -scheme AlarmOnCalendar -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Para compilar en un dispositivo hay que poner tu `DEVELOPMENT_TEAM` en
[`project.yml`](project.yml).

### Tests

46 tests sobre la lógica pura: reglas de filtrado en todos los casos de RSVP,
precedencia de la anulación manual, determinismo de los identificadores,
reconciliación del motor (incluido el comportamiento al tocar el tope) y
compatibilidad hacia atrás de los ajustes guardados.

Lo que **no** cubren hay que probarlo en un iPhone real. Comprobado en
dispositivo: la alarma suena con el móvil en silencio y con Concentración
activa. Queda por validar que el RSVP se resuelva bien en cuentas reales de
Google y Exchange — si `isCurrentUser` no se resolviera en alguna, el filtro
cae del lado seguro y el modo «solo confirmados» se comportaría como «todos»
en ese calendario.

## Licencia

Sin licencia declarada todavía. Mientras no se añada un archivo `LICENSE`, se
aplica el copyright por defecto: el código es visible, pero no hay permiso de uso
ni de redistribución.
