import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/entities/app_user_entity.dart';
import '../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  Future<bool> _hasConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  @override
  Stream<AppUserEntity?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return AppUserModel.fromFirestore(doc);
    });
  }

  @override
  Future<AppUserEntity?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return AppUserModel.fromFirestore(doc);
  }

  @override
  Future<AppUserEntity> signInWithGoogle() async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in aborted');

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    return _createOrUpdateUser(
      uid: user.uid,
      role: 'customer', // Default role for Google Sign In
      name: user.displayName ?? 'Google User',
      email: user.email,
      profilePhoto: user.photoURL,
    );
  }

  @override
  Future<AppUserEntity> signInDemoAsRole(String role) async {
    if (!await _hasConnectivity()) throw Exception('No internet connection.');

    UserCredential userCredential;
    try {
      userCredential = await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Demo sign in failed: $e');
    }

    final user = userCredential.user!;
    String name = '';
    String? restaurantId;
    String? driverId;

    if (role == 'customer') {
      name = 'Demo Customer';
    } else if (role == 'restaurant') {
      name = 'Demo Restaurant';
      restaurantId = 'restaurant_demo_1';
    } else if (role == 'driver') {
      name = 'Demo Driver';
      driverId = user.uid;
      
      // Also init driver profile
      await _firestore.collection('drivers').doc(user.uid).set({
        'name': name,
        'isAvailable': false,
        'vehicle': 'Demo Bike',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return _createOrUpdateUser(
      uid: user.uid,
      role: role,
      name: name,
      restaurantId: restaurantId,
      driverId: driverId,
    );
  }

  Future<AppUserEntity> _createOrUpdateUser({
    required String uid,
    required String role,
    required String name,
    String? email,
    String? profilePhoto,
    String? restaurantId,
    String? driverId,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();

    AppUserModel userModel;

    if (!doc.exists) {
      userModel = AppUserModel(
        uid: uid,
        role: role,
        name: name,
        email: email,
        profilePhoto: profilePhoto,
        restaurantId: restaurantId,
        driverId: driverId,
      );
      
      await docRef.set({
        ...userModel.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update existing
      final existingData = doc.data()!;
      userModel = AppUserModel(
        uid: uid,
        role: existingData['role'] ?? role, // Don't override existing role unless missing
        name: existingData['name'] ?? name,
        email: existingData['email'] ?? email,
        phone: existingData['phone'],
        address: existingData['address'],
        profilePhoto: existingData['profilePhoto'] ?? profilePhoto,
        restaurantId: existingData['restaurantId'] ?? restaurantId,
        driverId: existingData['driverId'] ?? driverId,
      );

      await docRef.update(userModel.toMap());
    }

    return userModel;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
