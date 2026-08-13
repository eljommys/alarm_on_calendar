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
