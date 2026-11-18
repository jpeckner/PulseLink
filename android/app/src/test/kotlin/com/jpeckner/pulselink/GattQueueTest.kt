// Copyright (c) 2026 Justin Peckner
// SPDX-License-Identifier: MIT
// See the LICENSE file in the project root for the full license text.

package com.jpeckner.pulselink

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class GattQueueTest {
    /** A scheduler whose actions run only when the test says so. */
    private class FakeScheduler : Scheduler {
        val actions = mutableListOf<() -> Unit>()
        var cancelled = 0

        override fun schedule(
            delayMillis: Long,
            action: () -> Unit,
        ): () -> Unit {
            actions.add(action)
            return { cancelled += 1 }
        }

        fun fireLatest() {
            actions.removeLastOrNull()?.invoke()
        }
    }

    private val scheduler = FakeScheduler()
    private val started = mutableListOf<String>()
    private val failed = mutableListOf<String>()

    /** Operations Android refuses to start. */
    private val refused = mutableSetOf<String>()

    /** Runs when an operation fails; tests set it to re-enter the queue. */
    private var onFail: (String) -> Unit = {}

    private val queue =
        GattQueue<String>(
            scheduler = scheduler,
            timeoutMillis = 5_000,
            start = { op ->
                started.add(op)
                op !in refused
            },
            fail = { op ->
                failed.add(op)
                onFail(op)
            },
        )

    @Test
    fun runsOneOperationAtATime() {
        queue.enqueue("discover")
        queue.enqueue("write")
        assertEquals(listOf("discover"), started)
        assertEquals("discover", queue.current)

        queue.finishCurrent()
        assertEquals(listOf("discover", "write"), started)
        assertEquals("write", queue.current)

        queue.finishCurrent()
        assertNull(queue.current)
        assertEquals(emptyList<String>(), failed)
    }

    @Test
    fun finishingCancelsTheTimeout() {
        queue.enqueue("discover")
        queue.finishCurrent()
        assertEquals(1, scheduler.cancelled)
    }

    @Test
    fun aRefusedStartFailsAndTheNextOneStarts() {
        refused.addAll(listOf("first", "second"))
        queue.enqueue("first")
        queue.enqueue("second")
        queue.enqueue("third")
        assertEquals(listOf("first", "second", "third"), started)
        assertEquals(listOf("first", "second"), failed)
        assertEquals("third", queue.current)
    }

    @Test
    fun aTimeoutFailsTheOperationAndTheNextOneStarts() {
        queue.enqueue("read")
        queue.enqueue("write")
        scheduler.fireLatest()
        assertEquals(listOf("read"), failed)
        assertEquals("write", queue.current)
    }

    @Test
    fun aTimeoutAfterFinishingDoesNothing() {
        queue.enqueue("read")
        val timeout = scheduler.actions.single()
        queue.finishCurrent()
        queue.enqueue("read")
        // The first read's timeout, firing late: the second read stays.
        timeout()
        assertEquals(emptyList<String>(), failed)
        assertEquals("read", queue.current)
    }

    @Test
    fun clearingDropsEverythingWithoutFailing() {
        queue.enqueue("discover")
        queue.enqueue("write")
        queue.clear()
        assertNull(queue.current)
        assertEquals(1, scheduler.cancelled)
        assertEquals(emptyList<String>(), failed)

        queue.finishCurrent()
        assertEquals(listOf("discover"), started)
    }

    @Test
    fun aFailureMayClearTheQueue() {
        onFail = { queue.clear() }
        queue.enqueue("discover")
        queue.enqueue("write")
        scheduler.fireLatest()
        assertEquals(listOf("discover"), started)
        assertNull(queue.current)
    }

    @Test
    fun aFailureMayQueueAnotherOperation() {
        refused.add("write")
        onFail = { op ->
            if (op == "write") {
                queue.enqueue("retry")
            }
        }
        queue.enqueue("write")
        queue.enqueue("read")
        // The retry starts at once, and "read" waits behind it.
        assertEquals(listOf("write", "retry"), started)
        assertEquals("retry", queue.current)

        queue.finishCurrent()
        assertEquals("read", queue.current)
    }
}
