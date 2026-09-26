# FireWatch — fire notification and evacuation mobile app

![FireWatch: a fire notification and evacuation research prototype. A phone shows a confirmed fire alert above a floor plan, with the escape route drawn from the user's position past the burning room to the nearest exit, and an "I am safe" button below it. Beside the phone, an isometric cutaway of the same floor shows occupants following that route.](docs/mobile_app_cover_image.png)

## 1. Overview

This Android application is the part of the FireWatch system that reaches the
people inside the building. When a fire is confirmed, the phone receives a push
notification within seconds and shows what is happening, which way to walk, and
what to do.

**Why it exists.** A review of 104 published fire detection studies found that
only 12.5 per cent consider the people inside the building. What usually reaches
them is a device name and a time. This application delivers the full response
instead:

- A situation report whose claims were checked against the evidence before it
  was sent.
- An escape route generated for this fire, avoiding every path close to it.
- The fuel class and the matching fire fighting guidance.
- How many people the camera can still see in the zone.
- A refuge instruction when no exit can be reached safely.

**How it connects to the web system:**

- The app is a client of `alert-service` in the sibling project
  `fire_detection_and_classification_web_app`, which runs on port 8090.
- The backend owns every judgement. The phone makes no detection decision of its
  own.
- The app reads the current state every fifteen seconds, and Firebase Cloud
  Messaging pushes an alert the moment something happens.
- Keeping all judgement on one side is deliberate, so the dashboard, the phone
  and the incident record cannot give three different answers.

**Research purpose:**

- It measures how long an alert takes to arrive, as a round trip on the server
  clock, so the handset clock cannot affect the figure.
- It records how many people marked themselves safe, kept separate from how many
  the camera could see. The difference between the two is itself a result.
- It is what the expert evaluation shows to practitioners when it compares the
  full response against a conventional alarm.

The application is a research prototype. Its guidance is advisory and does not
replace statutory signage or the instructions of a trained fire warden.

## 2. Main features

- **Four states, each shown differently.** Every state has its own screen, its
  own notification channel and its own wording, as Table 1 sets out.
- **A generated escape route.** The backend removes every path segment near the
  fire and finds the nearest exit still reachable. The app draws the route, marks
  the doors that are cut off, and gives the instruction in words.
- **A refuge instruction.** When no exit can be reached, the app says to shelter
  in place instead of showing a route through the fire.
- **Fire fighting guidance.** The screen shows what to use and what not to use.
  The text comes from the backend unchanged, so the phone and the dashboard
  cannot disagree.
- **A checked situation report.** Statements the evidence contradicts are
  removed before sending, and statements nothing can confirm are marked
  "unverified".
- **Occupant check-out.** A person can mark themselves out of the building. The
  count is kept separate from the camera head count and both are shown together.
- **An incident record.** The history screen opens a full record: the timeline,
  how much warning the sensors gave, the route taken, and both occupancy counts.
- **An alert that presents itself.** A confirmed fire is a full-screen Android
  notification on the fire channel, so a locked phone shows the alarm and the
  route can be read without unlocking. A gas warning never does this.
- **Either facility.** The app holds a floor plan for both the trial home and the
  demonstration hall, and draws whichever one the backend generated the route
  for. Nothing on the phone has to be changed to follow it.
- **It works when things go wrong.** The app runs with no backend and no Firebase
  configuration, and a push carries enough data to draw the full route offline.

**How each state reaches the phone** is shown in Table 1.

**Table 1.** How each system state is delivered to the phone and what it displays.

| State | Notification | What the screen shows |
|---|---|---|
| **Clear** | None. | The dashboard shows the site as all clear, with every zone and the system health. |
| **Gas warning** | A quiet channel, no sound, no alarm styling. | A calm advisory screen with the written warning and the sensor readings. No route, no muster and no evacuation, because nothing is burning. |
| **Gas danger** | The fire channel, loud. | An alarm screen that says dangerous gas with nothing seen on camera. It shows no confidence figure, because a carbon monoxide alarm legitimately has none. |
| **Fire confirmed** | The fire channel, loud. | The full fire screen: the situation report, how many people are still in the zone, the escape route drawn on the floor plan, and the instruction in words. |

When the fuel is later identified, the screen already open is **updated in
place** with the guidance. A second alert is never raised, because it is the
same fire with better information.

## 3. Technologies

Table 2 lists the technologies used to build the application.

**Table 2.** Technologies used in the implementation.

| Area | Technology |
|---|---|
| Framework | Flutter 3.44, Dart 3.12 |
| Platform | Android. Flutter is cross platform, so iOS remains a supported path. |
| Navigation | `go_router` |
| Networking | `http`, speaking JSON to the alert service |
| Push notifications | `firebase_core` and `firebase_messaging` |
| Local notifications | `flutter_local_notifications` |
| Local storage | `shared_preferences` |
| State | `ChangeNotifier` and `InheritedNotifier`, with no state package |
| Floor plan | A Flutter `CustomPainter` drawing a schematic of the building |

## 4. Setup and usage

**Requirements:**

- Flutter 3.44 or later.
- An Android device or emulator.
- The `alert-service` from the web project, running and reachable.
- Optional: a Firebase project, for real push notifications.

**Installation:**

```bash
flutter pub get
flutter run
```

**Connecting to the backend.** A phone cannot reach `localhost`, so it needs the
address of the machine running the backend:

```bash
# macOS or Linux
flutter run --dart-define=API_BASE_URL=http://$(ipconfig getifaddr en0):8090
```

```powershell
# Windows, PowerShell. Read the IPv4 Address of your Wi-Fi adapter first.
ipconfig
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8090
```

- With no address, the app uses `http://10.0.2.2:8090`, which is how an Android
  emulator reaches the host machine.
- The build is the only place the address comes from. There is no setting inside
  the app, so an installed build always talks to the server it was built for.

**Permissions.** The application declares only the three permissions in Table 3.

**Table 3.** Android permissions requested by the application.

| Permission | Why it is needed |
|---|---|
| `INTERNET` | To reach the alert service and Firebase. |
| `POST_NOTIFICATIONS` | Required on Android 13 and later. It is requested at startup. |
| `USE_FULL_SCREEN_INTENT` | Lets a confirmed fire take over a locked screen instead of waiting to be noticed. |

Accept the notification prompt when it appears, because it is what allows
Android to display alerts. On Android 14 and later, also turn on **Full screen
notifications** under Settings > Apps > FireWatch on any handset used for a
trial. Without it the fire alert still arrives, as an ordinary heads-up.

**Push notifications.** These need the two files in Table 4, which are not
included in this repository.

**Table 4.** Firebase credential files and where each one belongs.

| File | Where to put it |
|---|---|
| `google-services.json` | `android/app/` |
| `firebase-sa.json` | `alert-service/secrets/` in the web project |

The app builds and runs without them. Every screen still works, and the backend
logs the notifications it would have sent.

**Testing it without a fire.** With the backend running:

```bash
# macOS or Linux
curl -X POST localhost:8090/api/test-alert -d '{}'                              # a fire
curl -X POST localhost:8090/api/test-alert -H 'content-type: application/json' \
     -d '{"severity":"warning"}'                                                # a quiet gas warning
curl -X POST localhost:8090/api/test-alert -H 'content-type: application/json' \
     -d '{"severity":"gas_danger"}'                                             # a gas alarm
```

```powershell
# Windows, PowerShell
$u = "http://localhost:8090/api/test-alert"
Invoke-RestMethod -Method Post -Uri $u                                    # a fire
Invoke-RestMethod -Method Post -Uri $u -ContentType application/json `
  -Body '{"severity":"warning"}'                                          # a quiet gas warning
Invoke-RestMethod -Method Post -Uri $u -ContentType application/json `
  -Body '{"severity":"gas_danger"}'                                       # a gas alarm
```

`Invoke-RestMethod` is used instead of `curl.exe` because PowerShell removes the
quotation marks inside a JSON string before `curl.exe` receives it, which makes the
request fail.

**Checks:**

```bash
flutter analyze            # must stay clean
flutter test               # widget and unit tests, all offline
flutter build apk --debug
```

## 5. Scope and design decisions

Each point is a decision taken for a stated reason.

- **Android is the target platform.** The trials need one platform that receives
  push notifications reliably. The code is Flutter, so iOS remains a supported
  path.
- **The floor plans are drawn in the app on purpose.** The backend owns the graph
  and the route; the app owns the artwork, which keeps the plan readable under
  pressure. Two plans are included: the home used in the trials and the
  demonstration hall.
- **The app chooses the plan from the data, not from a setting.** Every route
  names the site it was generated for, and the app draws it on that site's plan.
  A switch on the dashboard used to choose the plan instead, and nothing
  reconciled it with the backend, so a phone could be set to one building and
  shown a route computed for another.
- **A route for a building with no plan is refused.** If a route names a site
  this build has no drawing for, the app says why instead of drawing it. A
  correct path over the wrong plan would look just as convincing as a right one,
  and the two plans are at different scales, so the path would not even be
  close.
- **A check-out identifies a device, not a person.** This is what makes the count
  reliable, because a double tap or a retry counts once. It also means two people
  sharing a phone appear as one. No personal data is stored.
- **The head count measures one camera view.** Someone never in frame is not
  counted. This is why the app shows the check-out count and the camera count
  side by side and never merges them.
- **Fuel verdicts state their own confidence.** The app writes "Likely" and marks
  the verdict as unvalidated, because presenting an estimate as a finding could
  make a responder use the wrong agent.
- **Plain HTTP is used on the local network.** This avoids the self-signed
  certificate during trials. A real deployment would need HTTPS.
- **One light theme, by choice, including the splash screen.** The alarm screens
  then look the same on every device during the trials and the expert evaluation,
  whatever each handset's dark-mode setting says.
- **Scope of the safety claim.** This is a research prototype. Its guidance is
  advisory and does not override statutory signage or a trained fire warden.
