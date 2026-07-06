Done — the integration is fully built and verified. Here's the summary.

## What now works

When the vision system confirms a fire (YOLO + VLM agree), the phone gets an **FCM push**; tapping it opens the existing incident screen with the real detection (type, confidence, AI scene description). The dashboard and history now show **live backend state** instead of mock data, and incidents **auto-clear** ~30s after the fire stops (zone returns to "All clear", a history entry appears).

**New backend service** — `mid-demo-vision-system/alert-service/` (FastAPI, SQLite): holds zones/incidents/history, de-dupes so one fire = one push, sends FCM, and auto-clears. Wired into `docker-compose.yml` (publishes `:8090`) and `nginx.conf`. The browser dashboard reports confirmed fires via a small hook in `index.html`.

**Flutter app** — the mock repository became a live one (`ApiFireRepository`), plus `NotificationService` (FCM token registration, foreground heads-up, tap → `/incident`), config, JSON models, and the Android native setup (permissions, `fire_alerts` channel, icon/color, `applicationId = lk.pramudi.firewatch`, desugaring).

## Verified

- **Backend:** live-tested every endpoint — registration, fire event, dedupe (`already_active`), auto-clear → history, forced test-alert. ✅
- **Flutter:** `flutter analyze` clean, debug APK builds (`✓ Built app-debug.apk`), all 3 widget tests pass. ✅

## What I need from you (to turn on real push)

You offered to provide Firebase — here are the exact two files:

| File | Where to get it | Put it here |
| --- | --- | --- |
| `google-services.json` | Firebase Console → add an Android app with package `lk.pramudi.firewatch` → download | `firewatch/android/app/google-services.json` |
| `firebase-sa.json` | Firebase Console → Project settings → Service accounts → Generate new private key | `mid-demo-vision-system/alert-service/secrets/firebase-sa.json` |

That's it — create one Firebase project, register the Android app, grab those two files. (iOS is out of scope; there's no `ios/` folder.)

Until you add them, everything still runs — the app builds and shows live state, and the backend logs pushes instead of sending them. Both sides degrade gracefully (the google-services Gradle plugin only applies if the JSON is present; `fcm.py` disables sending if the key is absent).

## Running it (full steps + test flow in `INTEGRATION.md`)

### macOS / Linux

```bash
# Backend
cd mid-demo-vision-system && cp sample.env .env   # add GOOGLE_API_KEY
docker compose up --build

# App (phone + Mac on same Wi-Fi)
cd firewatch && flutter run --dart-define=API_BASE_URL=http://$(ipconfig getifaddr en0):8090
```

Then trigger a demo alert: `curl -X POST http://localhost:8090/api/test-alert` → the phone should buzz and open the incident screen. (You can also long-press the dashboard header to set the server URL in-app.)

### Windows

Prereqs: Docker Desktop, Flutter, and (for the app) Android tooling installed; Docker Desktop must be running.

```powershell
# Backend (PowerShell)
cd mid-demo-vision-system
copy sample.env .env        # then edit .env and add GOOGLE_API_KEY
docker compose up --build

# Find your Wi-Fi IPv4 address (phone + PC on same Wi-Fi)
ipconfig                    # look under your Wi-Fi adapter → "IPv4 Address"

# App — substitute the IPv4 from above (e.g. 192.168.1.42)
cd ..\firewatch
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8090
```

To auto-fill the IP in one line (PowerShell):

```powershell
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
flutter run --dart-define=API_BASE_URL=http://${ip}:8090
```

Then trigger a demo alert (PowerShell has `curl` aliased to `Invoke-WebRequest`, so use `curl.exe` or this):

```powershell
curl.exe -X POST http://localhost:8090/api/test-alert
# or, native PowerShell:
Invoke-RestMethod -Method Post -Uri http://localhost:8090/api/test-alert
```

The phone should buzz and open the incident screen. (You can also long-press the dashboard header to set the server URL in-app.)

> Notes for Windows:
> - Use **Command Prompt/PowerShell**, not WSL, if your Android device/emulator is registered with the Windows-side `adb` — otherwise Flutter won't see the phone.
> - `copy` is the `cmd`/PowerShell equivalent of `cp`; paths use `\` instead of `/`.
> - If the phone can't reach the backend, check Windows Firewall isn't blocking inbound `:8090` on your private network.

Once you drop in the two Firebase files and rebuild, push is live end-to-end. Want me to walk through the Firebase console steps in more detail, or help test once you've added them?
