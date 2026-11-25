// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import android.util.Log

/**
 * Where native code reports what's worth noting, at one of three levels:
 * - [logError]: an error that shouldn't happen, such as a bug (a strap id
 *   Dart couldn't have sent) or a system failure the app gets past (a
 *   permission revoked after it was checked);
 * - [logWarning]: an expected failure, such as a strap that didn't connect
 *   in time, which also goes back to Dart as a typed result;
 * - [logInfo]: a normal event, such as the strap disconnecting.
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

    /** Notes an expected failure, [message], under [tag], with its [error], if any. */
    fun logWarning(
        tag: String,
        message: String,
        error: Throwable? = null,
    )

    /** Notes a normal event, [message], under [tag], with an [error], if any. */
    fun logInfo(
        tag: String,
        message: String,
        error: Throwable? = null,
    )
}

/**
 * Logs to Logcat at the error, warning or info level. A crash reporting
 * service would plug in here.
 */
// The one place logging straight to Logcat is allowed; see
// ForbiddenMethodCall in android/config/detekt.yml.
@Suppress("ForbiddenMethodCall")
class LogcatTracker : ErrorTracker {
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

    override fun logWarning(
        tag: String,
        message: String,
        error: Throwable?,
    ) {
        // Redacted, as in logError.
        val redactedMessage = message.redactedValue
        val redactedError = error?.redactedValue

        // Forward to your crash reporting service (e.g., Crashlytics, DataDog),
        // as a breadcrumb sent with the next report
        // FirebaseCrashlytics.getInstance().log(redactedMessage)

        Log.w(tag, redactedMessage, redactedError)
    }

    override fun logInfo(
        tag: String,
        message: String,
        error: Throwable?,
    ) {
        // Redacted, as in logError.
        val redactedMessage = message.redactedValue
        val redactedError = error?.redactedValue

        // Forward to your crash reporting service (e.g., Crashlytics, DataDog),
        // as a breadcrumb sent with the next report
        // FirebaseCrashlytics.getInstance().log(redactedMessage)

        Log.i(tag, redactedMessage, redactedError)
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
