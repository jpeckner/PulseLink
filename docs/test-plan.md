# Manual test plan

Checks that need a real phone and strap: BLE doesn't work in the iOS
Simulator, and these cover what unit and widget tests can't. Run them on a
debug build (`flutter run` on a connected iPhone) before merging an epic into
`develop`, and note each run in the log at the end.

Each milestone adds its own section. Milestone 6 will add walking out of
range and back, toggling Bluetooth while connected, backgrounding the app,
and killing and reopening it.

## Setup

- An iPhone with Bluetooth on, and PulseLink's Bluetooth permission not yet
  decided (delete and reinstall the app to reset it).
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

## Run log

| Date | Build (commit) | Phone and iOS | Strap | Result |
| --- | --- | --- | --- | --- |
