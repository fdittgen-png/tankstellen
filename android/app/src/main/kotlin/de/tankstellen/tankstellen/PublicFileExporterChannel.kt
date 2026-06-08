// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

package de.tankstellen.tankstellen

import android.content.ContentUris
import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Writes exports to the device's **public** Downloads collection (#2014).
 *
 * Replaces the previous Dart-side `LocalFileSaver`, which wrote to the
 * app's private documents directory — invisible to the user's Files app
 * and the Downloads chooser. On API 29+ this uses `MediaStore.Downloads`
 * (no manifest permission needed); on pre-Q it writes directly to
 * `Environment.getExternalStoragePublicDirectory(DIRECTORY_DOWNLOADS)`,
 * which is best-effort (most pre-Q devices accept the write without
 * WRITE_EXTERNAL_STORAGE for app-owned files).
 */
object PublicFileExporterChannel {
    private const val CHANNEL = "tankstellen/public_files"

    fun registerWith(flutterEngine: FlutterEngine, context: Context) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBytes" -> {
                    val fileName = call.argument<String>("fileName")
                    val mimeType = call.argument<String>("mimeType")
                    val bytes = call.argument<ByteArray>("bytes")
                    if (fileName == null || mimeType == null || bytes == null) {
                        result.error(
                            "ARGS",
                            "fileName, mimeType, and bytes are required",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    try {
                        val location = saveBytes(context, fileName, mimeType, bytes)
                        result.success(location)
                    } catch (e: Exception) {
                        result.error("WRITE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveBytes(
        context: Context,
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = context.contentResolver
            // #3084 — a prior export interrupted between insert and the
            // IS_PENDING=0 finalize leaves an orphaned MediaStore row
            // (_size=null) that makes a same-name re-insert fail with
            // "Failed to build unique file". Clear any app-owned stale row for
            // this name first (best-effort), then insert; on ANY collision /
            // failure, fall back to a timestamped unique name so the export
            // never hard-fails on the user.
            deleteExistingDownloads(resolver, fileName)
            return try {
                insertIntoDownloads(resolver, fileName, mimeType, bytes)
            } catch (e: Exception) {
                insertIntoDownloads(resolver, uniqueName(fileName), mimeType, bytes)
            }
        }
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        if (!downloads.exists()) downloads.mkdirs()
        val file = File(downloads, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }

    /** Insert [bytes] into MediaStore.Downloads under [displayName] (API 29+). */
    private fun insertIntoDownloads(
        resolver: ContentResolver,
        displayName: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        val uri = resolver.insert(collection, values)
            ?: throw IllegalStateException("MediaStore.insert returned null")
        resolver.openOutputStream(uri)?.use { it.write(bytes) }
            ?: throw IllegalStateException("openOutputStream returned null")
        values.clear()
        values.put(MediaStore.Downloads.IS_PENDING, 0)
        resolver.update(uri, values, null, null)
        return uri.toString()
    }

    /**
     * Best-effort: delete any app-owned Downloads row whose display name is
     * exactly [fileName], clearing a stale/orphaned entry that would block a
     * same-name insert. Failures are swallowed — the caller's unique-name
     * fallback still guarantees the export succeeds.
     */
    private fun deleteExistingDownloads(resolver: ContentResolver, fileName: String) {
        try {
            val collection = MediaStore.Downloads.EXTERNAL_CONTENT_URI
            resolver.query(
                collection,
                arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME} = ?",
                arrayOf(fileName),
                null,
            )?.use { cursor ->
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
                while (cursor.moveToNext()) {
                    val itemUri =
                        ContentUris.withAppendedId(collection, cursor.getLong(idColumn))
                    try {
                        resolver.delete(itemUri, null, null)
                    } catch (_: Exception) {
                        // Not ours / already gone — leave it; the fallback name handles it.
                    }
                }
            }
        } catch (_: Exception) {
            // Query unavailable — fall through to the insert + unique-name fallback.
        }
    }

    /** Insert a millisecond stamp before the extension: `name-<ts>.ext`. */
    private fun uniqueName(fileName: String): String {
        val stamp = System.currentTimeMillis()
        val dot = fileName.lastIndexOf('.')
        return if (dot > 0) {
            "${fileName.substring(0, dot)}-$stamp${fileName.substring(dot)}"
        } else {
            "$fileName-$stamp"
        }
    }
}
