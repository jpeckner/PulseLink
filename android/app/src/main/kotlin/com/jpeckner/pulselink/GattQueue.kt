// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

/** Runs an action after a delay. [GattQueue]'s timeouts use it, and tests replace it. */
fun interface Scheduler {
    /** Runs [action] after [delayMillis]; the returned function cancels it. */
    fun schedule(
        delayMillis: Long,
        action: () -> Unit,
    ): () -> Unit
}

/**
 * Runs GATT operations one at a time. Android's BluetoothGatt handles one
 * operation at once: starting another before the last one's callback
 * arrives makes the call return false (or, on some phones, drops it
 * silently). iOS's CoreBluetooth queues operations itself, so the Swift has
 * no counterpart.
 *
 * Each operation is started by [start], which returns false if Android
 * refused it, and ends when its callback calls [finishCurrent]. If the
 * callback doesn't arrive within [timeoutMillis], or the start is refused,
 * the operation is passed to [fail] and the next one starts.
 *
 * Not thread-safe: call it, and the scheduler's actions, on one thread.
 * LeConnection uses the main thread.
 */
class GattQueue<Op : Any>(
    private val scheduler: Scheduler,
    private val timeoutMillis: Long,
    private val start: (Op) -> Boolean,
    private val fail: (Op) -> Unit,
) {
    private val waiting = ArrayDeque<Op>()

    /** The operation waiting for its callback, if any. */
    private var running: Running<Op>? = null

    /**
     * The started operation waiting for its callback, if any. A callback
     * checks this is its own before calling [finishCurrent]; one that isn't
     * is late, from an operation that has since timed out.
     */
    val current: Op?
        get() = running?.op

    /** Runs [op] after the ones already waiting. */
    fun enqueue(op: Op) {
        waiting.addLast(op)
        startNext()
    }

    /**
     * Ends the current operation, whose callback has arrived, and starts the
     * next. The next may start before the caller has handled the result;
     * a result that ends the connection calls [clear].
     */
    fun finishCurrent() {
        val finished = running ?: return
        running = null
        finished.cancelTimeout()
        startNext()
    }

    /** Drops every operation, running or waiting, without failing them. */
    fun clear() {
        waiting.clear()
        val dropped = running ?: return
        running = null
        dropped.cancelTimeout()
    }

    private fun startNext() {
        // A loop rather than recursion, since several starts in a row may
        // be refused. `fail` may enqueue or clear; each pass rechecks.
        while (running == null) {
            val op = waiting.removeFirstOrNull() ?: return
            val next = Running(op)
            running = next
            if (start(op)) {
                next.cancelTimeout = scheduler.schedule(timeoutMillis) { timedOut(next) }
                return
            }
            running = null
            fail(op)
        }
    }

    private fun timedOut(timed: Running<Op>) {
        // Compared by identity: the same operation may be queued twice.
        if (running !== timed) {
            return
        }
        running = null
        fail(timed.op)
        startNext()
    }

    /** A started operation, and how to cancel its timeout. */
    private class Running<Op>(val op: Op) {
        var cancelTimeout: () -> Unit = {}
    }
}
