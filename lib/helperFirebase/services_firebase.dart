

// ===== Services =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Stream<User?> get auth$ => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    return cred;
  }

  Future<void> signOut() => _auth.signOut();

  User? get current => _auth.currentUser;
}

class UserRepo {
  final _col = FirebaseFirestore.instance.collection('users');

  Future<void> createUserDoc({required User user, required String name}) async {
    await _col.doc(user.uid).set({
      'uid': user.uid,
      'name': name,
      'email': user.email,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeenAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> users$() {
    return _col.orderBy('createdAt', descending: true).limit(100).snapshots();
  }

  Future<void> touchLastSeen(String uid) {
    return _col.doc(uid).update({'lastSeenAt': FieldValue.serverTimestamp()});
  }
}

final authService = AuthService();
final userRepo = UserRepo();