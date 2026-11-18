// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log

/**
 * Answers `openAppSettings` (see pigeons/app_settings_api.dart) by opening
 * PulseLink's App info page in Settings, where the user can allow Bluetooth
 * under Permissions.
 *
 * Pigeon runs this on the main thread.
 */
class AppSettingsOpener(private val context: Context) : AppSettingsApi {
    override suspend fun openAppSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        return try {
            context.startActivity(intent)
            true
        } catch (error: ActivityNotFoundException) {
            // Some customized Android builds have no App info page. Dart
            // tells the user it couldn't open Settings.
            Log.w(TAG, "No activity can show this app's settings", error)
            false
        }
    }

    private companion object {
        const val TAG = "AppSettingsOpener"
    }
}
