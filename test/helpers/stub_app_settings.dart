import 'package:pulselink/data/app_settings.dart';

/// An [AppSettings] that records how often it was opened, and opens or not
/// as [opens] says.
class StubAppSettings implements AppSettings {
  new({this.opens = true});

  /// What [open] completes with.
  bool opens;

  int openCount = 0;

  @override
  Future<bool> open() async {
    openCount++;
    return opens;
  }
}
