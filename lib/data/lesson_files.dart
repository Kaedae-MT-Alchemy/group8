import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../backend/backend.dart';

/// Course files uploaded by admins and trainers (PDF, slides, documents,
/// short videos). Firestore documents are capped at 1 MB, so each file is
/// stored as binary chunks:
///
///     lessonFiles/{id}                 name, mime, size, chunks, createdAt
///     lessonFiles/{id}/chunks/{index}  index, data (bytes)
///
/// Larger videos belong on YouTube or another video host; paste the link.
class LessonFiles {
  LessonFiles._();

  static const maxBytes = 10 * 1024 * 1024;
  static const _chunkBytes = 900 * 1024;
  static final _cache = <String, Uint8List>{};

  static String mimeFor(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'mp4' || 'm4v' => 'video/mp4',
      'webm' => 'video/webm',
      'mov' => 'video/quicktime',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'odp' => 'application/vnd.oasis.opendocument.presentation',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'odt' => 'application/vnd.oasis.opendocument.text',
      'rtf' => 'application/rtf',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }

  /// Stores [bytes] and returns the new file id. [onProgress] gets 0..1.
  static Future<String> upload(
    Uint8List bytes,
    String name, {
    String uploadedBy = '',
    void Function(double done)? onProgress,
  }) async {
    if (bytes.isEmpty) throw ArgumentError('The file is empty.');
    if (bytes.length > maxBytes) {
      throw ArgumentError('Files must be 10 MB or smaller.');
    }
    final doc = Backend.db.collection('lessonFiles').doc();
    final count = (bytes.length / _chunkBytes).ceil();
    for (var i = 0; i < count; i++) {
      final end = ((i + 1) * _chunkBytes).clamp(0, bytes.length);
      await doc.collection('chunks').doc('$i').set({
        'index': i,
        'data': Blob(Uint8List.sublistView(bytes, i * _chunkBytes, end)),
      });
      onProgress?.call((i + 1) / (count + 1));
    }
    // Written last, so a file only appears once all of its chunks exist.
    await doc.set({
      'name': name,
      'mime': mimeFor(name),
      'size': bytes.length,
      'chunks': count,
      'uploadedBy': uploadedBy,
      'createdAt': DateTime.now().toIso8601String(),
    });
    onProgress?.call(1);
    _cache[doc.id] = bytes;
    return doc.id;
  }

  /// Downloads a stored file (cached for the session).
  static Future<Uint8List> load(String id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final doc = Backend.db.collection('lessonFiles').doc(id);
    final meta = (await doc.get()).data();
    if (meta == null) throw StateError('This file is no longer available.');
    final chunks = await doc.collection('chunks').orderBy('index').get();
    final builder = BytesBuilder(copy: false);
    for (final c in chunks.docs) {
      final data = c.data()['data'];
      builder.add(data is Blob ? data.bytes : Uint8List(0));
    }
    final bytes = builder.takeBytes();
    if (bytes.length != (meta['size'] as num? ?? bytes.length)) {
      throw StateError(
        'This file is incomplete. Ask an admin to upload it again.',
      );
    }
    return _cache[id] = bytes;
  }

  /// Removes a stored file and its chunks.
  static Future<void> delete(String id) async {
    _cache.remove(id);
    final doc = Backend.db.collection('lessonFiles').doc(id);
    final chunks = await doc.collection('chunks').get();
    for (final c in chunks.docs) {
      await c.reference.delete();
    }
    await doc.delete();
  }
}
