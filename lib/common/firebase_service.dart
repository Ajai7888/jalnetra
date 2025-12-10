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

  /// Storage instance for the configured bucket
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

      // Account verification flag for admin approval
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

  // ───────── SOS IMPLEMENTATION ─────────

  Future<void> sendSosNotification({
    required String userEmail,
    required String message,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        throw Exception("SOS sender is not authenticated.");
      }

      await _firestore.collection('sos_alerts').add({
        'senderId': currentUserId,
        'senderEmail': userEmail,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'New',
        'alertedRoles': [
          UserRole.fieldOfficer.toString().split('.').last,
          UserRole.supervisor.toString().split('.').last,
        ],
      });
      debugPrint('✅ SOS Alert logged by $userEmail');
    } catch (e) {
      debugPrint('🔥 SOS Notification Error: $e');
      rethrow;
    }
  }

  // ───────── ADMIN USER MANAGEMENT ─────────

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

  Future<void> removeUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Future<void> updateUserRole(
    String uid,
    UserRole newRole,
    bool isVerified,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole.toString().split('.').last,
      'isAccountVerified': isVerified,
    });
  }

  // ───────── READING SUBMISSION (OFFICER + PUBLIC) ─────────

  /// Field Officer / internal flow → writes to /readings
  Future<void> submitReading(WaterReading reading, File photoFile) async {
    await _submitReadingToCollection(
      collectionName: 'readings',
      reading: reading,
      photoFile: photoFile,
    );
  }

  /// Public flow → writes to /public_readings
  Future<void> submitPublicReading(WaterReading reading, File photoFile) async {
    await _submitReadingToCollection(
      collectionName: 'public_readings',
      reading: reading,
      photoFile: photoFile,
    );
  }

  /// Shared logic for uploading file + creating Firestore doc.
  /// This is where the **correct Firebase Storage download URL** is created.
  Future<void> _submitReadingToCollection({
    required String collectionName,
    required WaterReading reading,
    required File photoFile,
  }) async {
    try {
      // Ensure user is logged in
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'unauthenticated',
          message: 'User is not signed in while uploading.',
        );
      }

      // Sanitize path components
      final safeSiteId = reading.siteId
          .replaceAll(RegExp(r'[#\[\]\.\/\\]'), '')
          .trim();

      final safeTimestamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '',
      );

      final officerIdForFile = user.uid;
      final fileName = '${officerIdForFile}_$safeTimestamp.jpg';
      final filePath = '$collectionName/$safeSiteId/$fileName';

      debugPrint('📤 Uploading to: $filePath');

      final ref = _storage.ref(filePath);

      // Upload JPEG with content type
      final uploadTask = ref.putFile(
        photoFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('✅ Uploaded. URL: $downloadUrl');

      // Create Firestore doc
      final docRef = _firestore.collection(collectionName).doc();

      final finalReading = WaterReading(
        id: docRef.id,
        siteId: reading.siteId,
        officerId: user.uid, // enforced from auth
        waterLevel: reading.waterLevel,
        imageUrl: downloadUrl, // THIS is the valid URL used in dashboard
        location: reading.location,
        timestamp: reading.timestamp,
        isVerified: false,
        isManual: reading.isManual,
      );

      await docRef.set(finalReading.toMap());
    } on FirebaseException catch (e, st) {
      debugPrint('🔥 Firebase Storage/Firestore error');
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

  /// Stream for the 'Community Inputs' queue (unverified readings from OFFICERS).
  Stream<List<WaterReading>> getCommunityInputs() {
    return _firestore
        .collection('readings')
        .where('isVerified', isEqualTo: false)
        .orderBy('timestamp', descending: true)
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

  /// All verified readings (for history + trends)
  Stream<List<WaterReading>> getAllVerifiedReadings() {
    return _firestore
        .collection('readings')
        .where('isVerified', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => WaterReading.fromFirestore(doc)).toList(),
        );
  }
}
