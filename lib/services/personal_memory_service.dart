import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/personal_memory_model.dart';

/// PersonalMemoryService handles all Firestore and Supabase Storage
/// operations for the Personal Memories feature.
///
/// Firestore collection: top-level 'personal_memories' (consistent with
/// the existing flat-collection pattern used by 'reminders' and 'sessions').
///
/// Supabase Storage path: personal-memories/{patientId}/{timestamp}_{filename}
///
/// --- Future AI Integration ---
/// When an AI question-generation service is added, it should implement:
///   `Future<List<String>> generateQuestionSuggestions(String imageUrl)`
/// The caretaker will always review/edit AI suggestions before saving.
/// The service method [addMemory] and [updateMemory] do not need to change —
/// the AI layer sits between photo upload and the form screen, suggesting
/// questions that the caretaker edits before calling [addMemory].
class PersonalMemoryService {
  final CollectionReference _memoriesCollection =
      FirebaseFirestore.instance.collection('personal_memories');

  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── Photo Upload ───────────────────────────────────────────────────

  /// Upload a photo to Supabase Storage and return the public URL.
  /// Works across Android, iOS, and Web by using byte data.
  Future<String> uploadPhoto(String patientId, Uint8List imageBytes, String fileName) async {
    debugPrint('DEBUG: uploadPhoto started - patientId=$patientId, fileName=$fileName, bytes=${imageBytes.length}');
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = fileName.split('/').last.split('\\').last;
      final cleanName = safeName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
      final storagePath = '$patientId/${timestamp}_$cleanName';

      debugPrint('DEBUG: Starting Supabase uploadBinary to path: $storagePath');
      await _supabase.storage.from('personal-memories').uploadBinary(
        storagePath,
        imageBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      debugPrint('DEBUG: Supabase upload completed.');

      debugPrint('DEBUG: Getting public URL...');
      final downloadUrl = _supabase.storage.from('personal-memories').getPublicUrl(storagePath);
      debugPrint('DEBUG: Public URL received: ${downloadUrl.substring(0, downloadUrl.length > 60 ? 60 : downloadUrl.length)}...');

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('ERROR: uploadPhoto failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Delete a photo from Supabase Storage by its public URL.
  Future<void> deletePhoto(String imageUrl) async {
    try {
      debugPrint('DEBUG: deletePhoto started for URL: $imageUrl');
      final bucketUrlPart = '/object/public/personal-memories/';
      if (imageUrl.contains(bucketUrlPart)) {
        final pathIndex = imageUrl.indexOf(bucketUrlPart) + bucketUrlPart.length;
        final storagePath = imageUrl.substring(pathIndex);

        await _supabase.storage.from('personal-memories').remove([storagePath]);
        debugPrint('DEBUG: Photo deleted from Supabase Storage: $storagePath');
      } else {
        debugPrint('DEBUG: Could not parse Supabase path from URL. Skipping deletion.');
      }
    } catch (e) {
      debugPrint('ERROR: deletePhoto failed: $e');
      // Don't rethrow — the Firestore doc may already be deleted,
      // and a missing Storage file shouldn't block the user.
    }
  }

  // ─── Memory CRUD ───────────────────────────────────────────────────

  /// Add a new personal memory. Returns the Firestore document ID.
  Future<String> addMemory(PersonalMemoryModel memory) async {
    debugPrint('DEBUG: addMemory started');
    try {
      final map = memory.toMap();
      debugPrint('DEBUG: Memory map created, keys: ${map.keys.toList()}');
      final docRef = await _memoriesCollection.add(map);
      debugPrint('DEBUG: Memory added to Firestore with id: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('ERROR: addMemory failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get all memories for a specific patient, ordered by creation date.
  Future<List<PersonalMemoryModel>> getMemoriesForPatient(String patientId) async {
    debugPrint('DEBUG: getMemoriesForPatient started - patientId=$patientId');
    try {
      final snapshot = await _memoriesCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('DEBUG: Got ${snapshot.docs.length} memories from Firestore');

      return snapshot.docs
          .map((doc) => PersonalMemoryModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('ERROR: getMemoriesForPatient failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Update an existing memory.
  Future<void> updateMemory(PersonalMemoryModel memory) async {
    debugPrint('DEBUG: updateMemory started - memoryId=${memory.memoryId}');
    try {
      if (memory.memoryId == null) {
        throw Exception('Cannot update memory without an ID');
      }
      await _memoriesCollection.doc(memory.memoryId).update(memory.toMap());
      debugPrint('DEBUG: Memory updated in Firestore: ${memory.memoryId}');
    } catch (e, stackTrace) {
      debugPrint('ERROR: updateMemory failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Delete a memory document and its associated photo from Storage.
  Future<void> deleteMemory(String memoryId, String imageUrl) async {
    debugPrint('DEBUG: deleteMemory started - memoryId=$memoryId');
    try {
      // Delete the Firestore document
      await _memoriesCollection.doc(memoryId).delete();
      debugPrint('DEBUG: Memory deleted from Firestore: $memoryId');

      // Delete the photo from Storage (best-effort)
      if (imageUrl.isNotEmpty) {
        await deletePhoto(imageUrl);
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: deleteMemory failed: $e');
      debugPrint('ERROR: stackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Get a single memory by ID (for editing).
  Future<PersonalMemoryModel?> getMemory(String memoryId) async {
    debugPrint('DEBUG: getMemory started - memoryId=$memoryId');
    try {
      final doc = await _memoriesCollection.doc(memoryId).get();
      if (doc.exists) {
        debugPrint('DEBUG: Memory found');
        return PersonalMemoryModel.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }
      debugPrint('DEBUG: Memory not found');
      return null;
    } catch (e) {
      debugPrint('ERROR: getMemory failed: $e');
      return null;
    }
  }
}
