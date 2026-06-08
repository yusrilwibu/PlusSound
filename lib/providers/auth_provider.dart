import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic> _userData = {};
  bool _isLoading = false;
  String _errorMessage = '';

  User? get user => _user;
  Map<String, dynamic> get userData => _userData;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isPremium => _userData['isPremium'] == true;
  String get displayName => _userData['displayName'] ?? _user?.displayName ?? _user?.email?.split('@').first ?? 'Pengguna';
  String? get photoUrl => _userData['photoUrl'] ?? _user?.photoURL;
  String? get email => _user?.email;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _fetchUserData(user.uid);
    } else {
      _userData = {};
    }
    notifyListeners();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userData = doc.data() ?? {};
      } else {
        // Buat dokumen profil baru untuk pengguna baru
        _userData = {
          'displayName': _user?.displayName ?? _user?.email?.split('@').first ?? 'Pengguna',
          'email': _user?.email,
          'photoUrl': _user?.photoURL,
          'isPremium': false,
          'premiumExpiry': null,
          'createdAt': FieldValue.serverTimestamp(),
          'favorites': [],
          'playlists': [],
        };
        await _firestore.collection('users').doc(uid).set(_userData);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await cred.user?.updateDisplayName(displayName);
      // Simpan ke Firestore
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'photoUrl': null,
        'isPremium': false,
        'premiumExpiry': null,
        'createdAt': FieldValue.serverTimestamp(),
        'favorites': [],
        'playlists': [],
      });
      _userData = {'displayName': displayName, 'email': email, 'isPremium': false};
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          // Buat doc baru jika login pertama kali
          await _firestore.collection('users').doc(user.uid).set({
            'displayName': user.displayName ?? 'Pengguna',
            'email': user.email,
            'photoUrl': user.photoURL,
            'isPremium': false,
            'premiumExpiry': null,
            'createdAt': FieldValue.serverTimestamp(),
            'favorites': [],
            'playlists': [],
          });
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _errorMessage = 'Gagal masuk dengan Google. Pastikan SHA-1 sudah ditambahkan di Firebase.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userData = {};
    notifyListeners();
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    if (_user == null) return;
    try {
      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      _userData.addAll(updates);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  /// Tambahkan lagu ke favorit di Firestore
  Future<void> toggleFavorite(String songId) async {
    if (_user == null) return;
    final List favorites = List.from(_userData['favorites'] ?? []);
    if (favorites.contains(songId)) {
      favorites.remove(songId);
    } else {
      favorites.add(songId);
    }
    _userData['favorites'] = favorites;
    notifyListeners();
    await _firestore.collection('users').doc(_user!.uid).update({'favorites': favorites});
  }

  bool isFavorite(String songId) {
    return (_userData['favorites'] as List?)?.contains(songId) ?? false;
  }

  /// Aktifkan premium (mock payment)
  Future<void> activatePremium(String planType) async {
    if (_user == null) return;
    final now = DateTime.now();
    final expiry = planType == 'yearly'
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));
    await _firestore.collection('users').doc(_user!.uid).update({
      'isPremium': true,
      'premiumExpiry': Timestamp.fromDate(expiry),
      'premiumPlan': planType,
    });
    _userData['isPremium'] = true;
    _userData['premiumExpiry'] = Timestamp.fromDate(expiry);
    _userData['premiumPlan'] = planType;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email ini sudah digunakan. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'user-not-found':
        return 'Akun tidak ditemukan. Coba daftar dulu.';
      case 'wrong-password':
        return 'Kata sandi salah.';
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan ($code). Coba lagi.';
    }
  }
}
