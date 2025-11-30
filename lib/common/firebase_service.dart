// lib/common/firebase_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:jalnetra01/models/reading_model.dart';
import 'package:jalnetra01/models/user_models.dart';
import '../firebase_options.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Uses the instance variable for _storage (fixed for consistency)
  late final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: DefaultFirebaseOptions.currentPlatform.storageBucket,
  );

  // ───────── AUTH & USER MGMT ─────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signUp(
    String email,
    String password,
    String name,
    UserRole role, {
    String? phone,
    String? employeeId,
    String? department,
    String? designation,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user == null) return null;

      final appUser = AppUser(
        id: user.uid,
        name: name,
        email: email,
        role: role,
        phone: phone,
        employeeId: employeeId,
        department: department,
        designation: designation,
      );

      // Add an 'isVerified' flag for users to manage pending accounts (for Admin)
      final userMap = appUser.toMap()..['isAccountVerified'] = false;

      await _firestore.collection('users').doc(user.uid).set(userMap);
      return appUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('Sign Up Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Sign Up Error: $e');
      rethrow;
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return await getUserData(result.user!.uid);
    } catch (e) {
      debugPrint('Sign In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AppUser?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Safe casting for fromMap constructor
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AppUser.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Get User Data Error: $e');
      return null;
    }
  }

  // ───────── ADMIN USER MANAGEMENT ─────────

  /// Gets a stream of users filtered by their role (for Field Officer/Supervisor/Analyst pages).
  Stream<List<AppUser>> getUsersByRole(UserRole role) {
    final roleString = role.toString().split('.').last;
    return _firestore
        .collection('users')
        .where('role', isEqualTo: roleString)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return AppUser.fromMap(data);
          }).toList(),
        );
  }

  /// Gets a stream of users whose accounts are not yet verified by an Admin (for Approval Page).
  Stream<List<AppUser>> getUnverifiedUsers() {
    return _firestore
        .collection('users')
        .where('isAccountVerified', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return AppUser.fromMap(data);
          }).toList(),
        );
  }

  /// Removes the user's profile from Firestore. (Note: Full Auth deletion requires Admin SDK/Cloud Function).
  Future<void> removeUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  /// Updates a user's role and verification status.
  Future<void> updateUserRole(
    String uid,
    UserRole newRole,
    bool isVerified,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole.toString().split('.').last, // Save as string
      'isAccountVerified': isVerified,
    });
  }

  // ───────── READING SUBMISSION (FIXED) ─────────
  Future<void> submitReading(WaterReading reading, File photoFile) async {
    try {
      // 0. Make sure user is logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthenticated',
          message: 'User is not signed in while uploading.',
        );
      }

      // --- ENHANCEMENT: Structured File Naming ---

      // 1. Sanitize file path components
      final safeSiteId = reading.siteId
          .replaceAll(RegExp(r'[#\[\]\.\/\\]'), '')
          .trim();

      // ⚠️ FIX: Use a robust regex to keep only alphanumeric characters for the timestamp/filename segment.
      final safeTimestamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '',
      );

      final officerIdForFile = user.uid;
      final fileName = '${officerIdForFile}_$safeTimestamp.jpg';
      final filePath = 'readings/$safeSiteId/$fileName';

      debugPrint('📤 Uploading to: $filePath');

      final ref = _storage.ref(filePath);

      // 2. Upload file with minimal metadata
      final uploadTask = ref.putFile(
        photoFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Uploaded. URL: $downloadUrl');

      // 3. Save Firestore doc
      final finalReadingMap = WaterReading(
        id: '',
        siteId: reading.siteId,
        officerId: reading.officerId,
        waterLevel: reading.waterLevel,
        imageUrl: downloadUrl,
        location: reading.location,
        timestamp: reading.timestamp,
        isVerified: false,
        isManual: reading.isManual,
      ).toMap();

      final docRef = await _firestore
          .collection('readings')
          .add(finalReadingMap);

      await docRef.update({'id': docRef.id});
    } on FirebaseException catch (e, st) {
      debugPrint('🔥 Firebase Storage error');
      debugPrint('  code   : ${e.code}');
      debugPrint('  message: ${e.message}');
      debugPrint('  plugin : ${e.plugin}');
      debugPrint('  stack  : ${e.stackTrace ?? st}');
      rethrow;
    } catch (e, st) {
      debugPrint('Submit Reading Error (non-Firebase): $e');
      debugPrint('Stacktrace: $st');
      rethrow;
    }
  }

  // ───────── SUPERVISOR / ANALYST ─────────
  // ... (all other methods remain the same) ...

  Stream<List<WaterReading>> getPendingVerifications() {
    return _firestore
        .collection('readings')
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => WaterReading.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateVerificationStatus(
    String readingId,
    bool isVerified,
  ) async {
    await _firestore.collection('readings').doc(readingId).update({
      'isVerified': isVerified,
    });
  }

  Stream<List<WaterReading>> getAllVerifiedReadings() {
    return _firestore
        .collection('readings')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => WaterReading.fromFirestore(doc)).toList(),
        );
  }
}
