import UIKit

/// Answers `openAppSettings` (see pigeons/app_settings_api.dart) by opening
/// PulseLink's page in the Settings app, where the user can allow Bluetooth.
///
/// iOS ends the app when the user changes its Bluetooth permission, so a
/// user who allows it comes back to a fresh launch that can scan.
final class AppSettingsOpener: AppSettingsApi {
  func openAppSettings() async throws -> Bool {
    // No thread check needed: awaiting a main-actor method runs it on the
    // main actor, whichever thread this started on.
    await Self.open()
  }

  @MainActor
  private static func open() async -> Bool {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      // A system constant, so this can't happen; reported to Dart as not
      // opening rather than crashing.
      return false
    }
    return await UIApplication.shared.open(url)
  }
}
