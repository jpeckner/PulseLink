# domain

Plain Dart models (`HeartRateSample`; later `Session` and
`BluetoothConnectionState`) and the heart-rate packet parser. No Flutter, no
plugins, no I/O.

Terminology: "skin contact" (`SkinContact`) means the strap touching the
wearer's skin. Bluetooth connectivity is a separate concern and never uses the
word "contact".
