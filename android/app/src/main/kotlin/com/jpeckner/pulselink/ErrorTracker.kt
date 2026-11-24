// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.util.Log

/**
 * Where native code reports errors that shouldn't happen: a bug, such as a
 * strap id Dart couldn't have sent, or a system failure the app gets past,
 * such as a permission that was revoked after it was checked. Expected
 * failures, which go back to Dart as typed results, and normal events don't
 * come here: those use `Log.w` or `Log.i`, if at all.
 *
 * The Kotlin counterpart of Dart's `TrackerService`. MainActivity creates
 * the app's one and passes it, through constructors, to everything that
 * reports errors.
 *
 * Can be called from any thread.
 */
interface ErrorTracker {
    /** Reports [message], under [tag], with the [error] that caused it, if any. */
    fun logError(
        tag: String,
        message: String,
        error: Throwable? = null,
    )
}

/** Logs to Logcat at the error level. A crash reporting service would plug in here. */
class LogcatTracker : ErrorTracker {
    // The one place error-level logging is allowed; see ForbiddenMethodCall
    // in android/config/detekt.yml.
    @Suppress("ForbiddenMethodCall")
    override fun logError(
        tag: String,
        message: String,
        error: Throwable?,
    ) {
        // Redacted before anything leaves this method, so no report carries
        // personal information about the user, such as a strap's address.
        val redactedMessage = message.redactedValue
        val redactedError = error?.redactedValue

        // Forward to your crash reporting service (e.g., Crashlytics, DataDog)
        // FirebaseCrashlytics.getInstance().log(redactedMessage)
        // redactedError?.let { FirebaseCrashlytics.getInstance().recordException(it) }

        Log.e(tag, redactedMessage, redactedError)
    }
}

// Private to this file, so nothing else mistakes a placeholder for real
// redaction.

/**
 * This text with any personally identifiable information about the user
 * removed. A placeholder: nothing is removed yet.
 */
private val String.redactedValue: String
    get() = this

/**
 * This error, or one in its place, with any personally identifiable
 * information about the user removed from what it says, such as its
 * message. A placeholder: nothing is removed yet. A [Throwable], not the
 * error's own type, since redacting usually means making a new one.
 */
private val Throwable.redactedValue: Throwable
    get() = this
