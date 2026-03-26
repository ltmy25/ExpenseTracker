import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:expensetracker/core/constants/firestore_collections.dart';
import 'package:expensetracker/data/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-created');
    }

    await user.updateDisplayName(displayName);
    await user.reload();

    final refreshedUser = _firebaseAuth.currentUser ?? user;
    await refreshedUser.getIdToken(true);
    return _upsertUserProfile(
      refreshedUser,
      fallbackEmail: email,
      fallbackDisplayName: displayName,
    );
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    return _upsertUserProfile(
      user,
      fallbackEmail: email,
      fallbackDisplayName: user.displayName ?? '',
    );
  }

  Future<UserModel> signInWithGoogle() async {
    UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      credential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'sign-in-cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      credential = await _firebaseAuth.signInWithCredential(googleCredential);
    }

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }

    return _upsertUserProfile(
      user,
      fallbackEmail: user.email ?? '',
      fallbackDisplayName: user.displayName ?? 'Google User',
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore sign out errors from Google SDK and continue Firebase sign out.
      }
    }
    await _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<UserModel> updateProfile({
    required String displayName,
    String? photoUrl,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'user-not-logged-in');
    }

    await user.updateDisplayName(displayName);
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      await user.updatePhotoURL(photoUrl);
    }

    await user.reload();
    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) {
      throw FirebaseAuthException(code: 'user-not-logged-in');
    }

    final snapshot = await _usersRef.doc(refreshedUser.uid).get();
    final current = snapshot.exists && snapshot.data() != null
        ? UserModel.fromMap(snapshot.data()!, refreshedUser.uid)
        : UserModel.fromAuthUser(
            uid: refreshedUser.uid,
            email: refreshedUser.email ?? '',
            displayName: refreshedUser.displayName ?? displayName,
            photoUrl: refreshedUser.photoURL,
          );

    final updated = current.copyWith(
      displayName: displayName,
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );

    await _usersRef.doc(refreshedUser.uid).set(updated.toMap(), SetOptions(merge: true));
    return updated;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'user-not-logged-in');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return null;
    }

    final snapshot = await _usersRef.doc(user.uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      return UserModel.fromMap(snapshot.data()!, user.uid);
    }

    final fallback = UserModel.fromAuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      photoUrl: user.photoURL,
    );
    await _usersRef.doc(user.uid).set(fallback.toMap(), SetOptions(merge: true));
    return fallback;
  }

  CollectionReference<Map<String, dynamic>> get _usersRef {
    return _firestore.collection(FirestoreCollections.users);
  }

  Future<UserModel> _upsertUserProfile(
    User user, {
    required String fallbackEmail,
    required String fallbackDisplayName,
  }) async {
    final userDoc = _usersRef.doc(user.uid);
    final snapshot = await userDoc.get();

    if (!snapshot.exists || snapshot.data() == null) {
      final newProfile = UserModel.fromAuthUser(
        uid: user.uid,
        email: user.email ?? fallbackEmail,
        displayName: user.displayName ?? fallbackDisplayName,
        photoUrl: user.photoURL,
      );
      await _setUserProfileWithRetry(userDoc, newProfile.toMap(), user);
      return newProfile;
    }

    final profile = UserModel.fromMap(snapshot.data()!, user.uid).copyWith(
      displayName: user.displayName,
      photoUrl: user.photoURL,
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    await _setUserProfileWithRetry(userDoc, profile.toMap(), user);
    return profile;
  }

  Future<void> _setUserProfileWithRetry(
    DocumentReference<Map<String, dynamic>> userDoc,
    Map<String, dynamic> data,
    User user,
  ) async {
    try {
      await userDoc.set(data, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') {
        rethrow;
      }

      await user.getIdToken(true);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await userDoc.set(data, SetOptions(merge: true));
    }
  }
}
