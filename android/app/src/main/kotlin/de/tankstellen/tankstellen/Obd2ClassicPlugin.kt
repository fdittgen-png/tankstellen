package de.tankstellen.tankstellen

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.concurrent.thread

/**
 * In-repo MethodChannel plugin for Bluetooth Classic SPP RFCOMM,
 * the transport used by the vLinker FS OBD2 adapter (#763).
 *
 * Written in Kotlin inside this app to avoid the license problem:
 * the popular flutter_blue_classic package is GPL-3, incompatible
 * with this MIT project. Everything here is the Apache-licensed
 * Android Bluetooth API — no external plugin dependency.
 *
 * Channels:
 *  - "tankstellen.obd2/classic" (MethodChannel):
 *       bondedDevices() -> List<Map{address, name, bondState}>
 *       connect(address, uuid) -> Bool
 *       write(bytes) -> void
 *       disconnect() -> void
 *  - "tankstellen.obd2/classic/incoming" (EventChannel):
 *       Stream<List<int>> — bytes arriving from the socket's
 *       InputStream, pushed on a background reader thread.
 *
 * The Dart-side `PluginClassicBluetoothFacade` is the only caller.
 *
 * Threading: Android's BluetoothSocket I/O MUST NOT happen on the
 * main thread. `connect()` does the dial on a background thread and
 * completes a MethodChannel.Result when done. The reader thread runs
 * for the lifetime of the connection and pushes bytes to the
 * EventChannel's sink from whichever thread — Flutter's platform-
 * channel plumbing marshals to the main thread for delivery.
 */
object Obd2ClassicPlugin {
    private const val TAG = "Obd2ClassicPlugin"
    private const val METHOD_CHANNEL = "tankstellen.obd2/classic"
    private const val INCOMING_CHANNEL = "tankstellen.obd2/classic/incoming"

    private var socket: BluetoothSocket? = null
    private var readerThread: Thread? = null
    private val readerRunning = AtomicBoolean(false)
    private var eventSink: EventChannel.EventSink? = null

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        val method = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        val events = EventChannel(flutterEngine.dartExecutor.binaryMessenger, INCOMING_CHANNEL)

        method.setMethodCallHandler { call, result -> handle(call, result, context) }
        events.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result, context: Context) {
        try {
            when (call.method) {
                "bondedDevices" -> result.success(bondedDevices(context))
                "connect" -> {
                    val address = call.argument<String>("address")
                        ?: return result.error("arg", "address missing", null)
                    val uuid = call.argument<String>("uuid")
                        ?: return result.error("arg", "uuid missing", null)
                    thread(name = "obd2-classic-connect") {
                        val ok = connect(context, address, uuid)
                        result.success(ok)
                    }
                }
                "write" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: return result.error("arg", "bytes missing", null)
                    writeBytes(bytes, result)
                }
                "disconnect" -> {
                    disconnect()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "handle ${call.method} failed", e)
            result.error("platform", e.message ?: e.javaClass.simpleName, null)
        }
    }

    private fun bondedDevices(context: Context): List<Map<String, Any?>> {
        val adapter = adapterOrNull(context) ?: return emptyList()
        // Requires BLUETOOTH_CONNECT on Android 12+. Caller gates
        // this via Obd2Permissions before invoking us.
        @Suppress("MissingPermission")
        val bonded = adapter.bondedDevices ?: return emptyList()
        return bonded.map { d ->
            mapOf(
                "address" to d.address,
                "name" to (d.name ?: ""),
            )
        }
    }

    private fun connect(context: Context, address: String, uuid: String): Boolean {
        disconnect() // ensure any prior socket is closed
        val adapter = adapterOrNull(context) ?: return false
        @Suppress("MissingPermission")
        val device = try {
            adapter.getRemoteDevice(address)
        } catch (e: IllegalArgumentException) {
            Log.e(TAG, "connect: bad address $address", e)
            return false
        }
        return try {
            @Suppress("MissingPermission")
            val s = device.createRfcommSocketToServiceRecord(UUID.fromString(uuid))
            @Suppress("MissingPermission")
            adapter.cancelDiscovery() // required before connect()
            s.connect()
            socket = s
            startReader()
            true
        } catch (e: IOException) {
            Log.e(TAG, "connect: RFCOMM open failed", e)
            try { socket?.close() } catch (_: IOException) {}
            socket = null
            false
        }
    }

    private fun startReader() {
        readerRunning.set(true)
        readerThread = thread(name = "obd2-classic-read") {
            val s = socket ?: return@thread
            val buffer = ByteArray(256)
            try {
                val input = s.inputStream
                while (readerRunning.get()) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    if (n == 0) continue
                    val slice = buffer.copyOfRange(0, n).toList()
                    val sink = eventSink
                    if (sink != null) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            sink.success(slice)
                        }
                    }
                }
            } catch (e: IOException) {
                Log.w(TAG, "reader: $e")
            }
        }
    }

    private fun writeBytes(bytes: ByteArray, result: MethodChannel.Result) {
        val s = socket ?: return result.error("state", "not connected", null)
        thread(name = "obd2-classic-write") {
            try {
                s.outputStream.write(bytes)
                s.outputStream.flush()
                result.success(true)
            } catch (e: IOException) {
                Log.e(TAG, "write failed", e)
                result.error("io", e.message ?: "write failed", null)
            }
        }
    }

    private fun disconnect() {
        readerRunning.set(false)
        try { socket?.close() } catch (_: IOException) {}
        socket = null
        readerThread = null
    }

    private fun adapterOrNull(context: Context): BluetoothAdapter? {
        return try {
            (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
        } catch (e: Exception) {
            Log.e(TAG, "adapter fetch failed", e)
            null
        }
    }
}
