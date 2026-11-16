# Manual test plan

Checks that need a real phone and strap: BLE doesn't work in the iOS
Simulator or the Android emulator, and these cover what unit and widget tests
can't. Run them on a debug build (`flutter run` on a connected iPhone or
Android phone) before merging an epic into `develop`, and note each run in
the log at the end. The Apple Watch checks need an iPhone and its paired
watch, but no strap: demo mode drives them.

Each milestone adds its own section. Milestone 6 will add walking out of
range and back, toggling Bluetooth while connected, backgrounding the app
(on both platforms, once Android's background streaming lands), and killing
and reopening it.

## Setup

- An iPhone, or an Android phone with Android 12 or later, with Bluetooth
  on, and PulseLink's Bluetooth permission not yet decided (delete and
  reinstall the app to reset it).
- A heart-rate strap that supports Bluetooth (not only ANT+). Dampen its
  electrodes and wear it. Without one, a second phone running nRF Connect
  can act as a heart-rate sensor.
- Nothing else connected to the strap: no other phone, watch or gym machine.

## Milestone 3: Real BLE on iOS

### Demo mode

- [ ] **Launch:** the app opens in demo mode, with a "Demo" badge, a moving
  bpm, the update time, and an 80% battery in the app bar.

### Finding a strap

- [ ] **First scan asks for permission:** tap **Find strap**. iOS asks for
  Bluetooth permission (with the `Info.plist` text). Allow it. The picker
  says it's looking for heart-rate straps.
- [ ] **Strap listed:** the strap appears by name within a few seconds.
- [ ] **Tips:** with the strap off or far away, tips about dampening the
  strap and disconnecting other devices appear after about 15 seconds.
- [ ] **Already connected:** connect the strap to another app on the phone
  (such as the strap maker's app), then open the picker. The strap is listed
  with a green check, and the progress bar is hidden.
- [ ] **Bluetooth off while scanning:** turn Bluetooth off in Control Center
  with the picker open. It says "Bluetooth is off". Turn it back on, and
  scanning resumes by itself.
- [ ] **Closing stops the scan:** close the picker. No strap is connected,
  and the live screen still shows demo data.

### Connecting and live data

- [ ] **Connect:** pick the strap. The Demo badge goes, and a live bpm
  arrives within a few seconds, close to the strap maker's app.
- [ ] **Skin contact:** take the strap off. The screen says there's no skin
  contact (or shows "--" for a strap that can't detect contact). Put it back
  on, and the bpm returns.
- [ ] **Battery:** the app bar shows the strap's battery level, matching the
  strap maker's app. A strap without the Battery Service shows no battery
  and still connects.

### Failures

- [ ] **Strap disconnected:** while connected, take the strap's battery out
  or walk far away. "Strap disconnected" appears straight away, not after 10
  seconds. Put the battery back, tap **Try again**, and it reconnects.
- [ ] **Can't reach the strap:** pick a strap, then turn it off before it
  connects. After about 10 seconds, the screen says "Can't reach the strap".
- [ ] **Not a heart-rate strap:** using nRF Connect, advertise the Heart Rate
  Service with no Heart Rate Measurement characteristic, then pick it. The
  screen says "Not a heart-rate strap".
- [ ] **Bluetooth off:** turn Bluetooth off, then tap **Try again** or open
  the picker. Both say "Bluetooth is off", with no Open Settings button.
- [ ] **Permission denied:** in Settings > PulseLink, turn Bluetooth off.
  Reopen PulseLink (iOS restarts it), then open the picker. It says
  "Bluetooth permission needed", with an **Open Settings** button.
- [ ] **Open Settings:** tap **Open Settings**. Settings opens on PulseLink's
  page. Allow Bluetooth and go back. PulseLink restarts and can scan.

### Debug override

- [ ] **On a real strap:** while connected, long-press the title and step
  through **Override: …**. Each condition shows its warning, and **None**
  shows the strap's own reading again.

## Milestone 4: Real BLE on Android

The Milestone 3 checks, on an Android phone. Where Android differs from iOS,
the check says so.

### Demo mode

- [ ] **Launch:** as on iOS.

### Finding a strap

- [ ] **First scan asks for permission:** tap **Find strap**. Android asks
  whether PulseLink may find and connect to nearby devices. Allow it. The
  picker says it's looking for heart-rate straps.
- [ ] **Strap listed:** the strap appears by name within a few seconds.
- [ ] **Tips:** as on iOS, after about 15 seconds.
- [ ] **Already connected:** connect the strap to another app on the phone,
  then open the picker. The strap is listed with a green check. Android only
  knows it's a heart-rate strap if this phone has connected to it before, so
  if it's missing, connect to it once in PulseLink and try again.
- [ ] **Bluetooth off while scanning:** turn Bluetooth off in Quick Settings
  with the picker open. It says "Bluetooth is off". Turn it back on, and
  scanning resumes by itself.
- [ ] **Scan limit:** open and close the picker six times within 30 seconds.
  The sixth time, the strap may take up to 30 seconds to appear, but it does
  appear. (Without the throttle, Android would silently find nothing.)
- [ ] **Closing stops the scan:** close the picker. No strap is connected,
  and the live screen still shows demo data.

### Connecting and live data

- [ ] **Connect, skin contact, battery:** as on iOS.

### Failures

- [ ] **Strap disconnected, can't reach the strap, not a heart-rate strap,
  Bluetooth off:** as on iOS.
- [ ] **Permission refused:** reinstall the app, tap **Find strap**, and
  choose **Don't allow**. The picker says "Bluetooth permission needed", with
  an **Open Settings** button. Close and reopen the picker: Android asks once
  more. Refuse again, and from then on Android refuses without asking, and
  the picker says the same.
- [ ] **Open Settings:** tap **Open Settings**. PulseLink's App info page
  opens. Under **Permissions > Nearby devices**, choose **Allow**, then go
  back. The open picker starts scanning by itself; Android doesn't restart
  the app, as iOS does.
- [ ] **Android 12:** if you have a phone on Android 12, connect and check
  live bpm and battery there too. Android 13 changed the Bluetooth calls the
  app uses, so both versions take different paths.

### Debug override

- [ ] **On a real strap:** as on iOS.

## Milestone 5: Apple Watch app

### Setup

- An iPhone and its paired Apple Watch, with Developer Mode on in the
  watch's Settings > Privacy & Security.
- Run the phone app from Xcode or `flutter run`. The watch app comes with
  it: the iPhone installs it on the watch, which can take a minute. If it
  doesn't appear, install it from the Watch app on the iPhone (My Watch >
  PulseLink Debug, for a debug build), or run the `PulseLinkWatch` scheme
  from Xcode. Each build's watch app talks only to the phone app of the
  same build (debug, profile or release).
- Demo mode is enough for every check except the last section.

### Live data

- [ ] **Live:** open the watch app with the phone app showing demo data.
  The watch shows "Demo", the same bpm as the phone, and "Updated" with
  the time, changing about once a second.
- [ ] **Stale:** close the phone app. About 10 seconds after the last
  reading, the bpm dims and the watch says "No data from strap" and "Last
  reading" with its time.
- [ ] **Latest state on launch:** with the phone app still closed, close and
  reopen the watch app. It shows the same stale reading straight away, not
  "Open PulseLink on your iPhone".
- [ ] **Phone app back:** open the phone app again. The watch shows
  "Waiting for heart-rate data…", then live data within a few seconds.

### Reachability

- [ ] **No flash:** lower your wrist, wait for the screen to dim, and raise
  it, a few times. "iPhone not reachable" doesn't appear, even briefly.
- [ ] **iPhone out of reach:** turn on Airplane Mode on the iPhone. About 5
  seconds later, the watch shows "iPhone not reachable" over the last state,
  and the reading goes stale. Turn Airplane Mode off: the banner goes and
  live data returns.

### What the phone shows, on the watch

- [ ] **Debug override:** on the phone, long-press the title and step
  through the overrides. Within a second or two, the watch shows the match:
  "No skin contact", "Strap connected, no heart rate yet" (0 bpm), "Strap
  reading out of range", or a stale reading for no data. **None** brings
  back the live bpm.
- [ ] **With a strap:** pick a strap on the phone. The watch's "Demo" tag
  goes, and it shows the strap's bpm. Take the strap's battery out: the
  watch shows "Strap disconnected" with the last reading dimmed.

### Known issue

Installing a new build of the iPhone app from Xcode can remove the watch
app from the watch. Not yet explained: the builds embed the watch app
correctly, signed, with matching versions. Tabled for now. When it happens,
note whether it comes back by itself, and whether the Watch app on the
iPhone shows PulseLink with an Install button.

## Run log

| Date | Build (commit) | Phone and OS | Strap | Result |
| --- | --- | --- | --- | --- |
| 2026-11-15 | 68e2e19 (Milestone 4 epic plus the shelved background branch) | Samsung Galaxy A36 5G, Android 16 | COOSPO Armband Heart Rate Monitor | Pass: scanning, connecting, live bpm, battery and background streaming, checked before this checklist was written |
| 2026-11-15 | 6b4f5e5 (Milestone 5 epic) | iPhone 17 Pro Max, iOS 27.0.1, with Apple Watch Series 9, watchOS 27.0.1 | None (demo mode) | Pass, except that "iPhone not reachable" flashed each time the wrist was raised; checked before this checklist was written |
| 2026-11-15 | 4877cf4 (the reachability fix) | iPhone 17 Pro Max, iOS 27.0.1, with Apple Watch Series 9, watchOS 27.0.1 | None (demo mode) | Pass: no flash on raising the wrist |
