// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

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
