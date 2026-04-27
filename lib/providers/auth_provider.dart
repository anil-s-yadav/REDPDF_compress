// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../domain/repositories/auth_repository.dart';
// import '../domain/repositories/user_repository.dart';
// import '../domain/models/user_model.dart';

// class AuthProvider with ChangeNotifier {
//   final AuthRepository _authRepository;
//   final UserRepository _userRepository;

//   User? _firebaseUser;
//   UserModel? _userModel;
//   bool _isLoading = false;
//   int _guestConversionCount = 0;
//   DateTime _lastGuestConversionDate = DateTime.now();

//   AuthProvider(this._authRepository, this._userRepository) {
//     _authRepository.authStateChanges.listen(_onAuthStateChanged);
//   }

//   User? get firebaseUser => _firebaseUser;
//   UserModel? get userModel => _userModel;
//   bool get isLoading => _isLoading;
//   bool get isAuthenticated => _firebaseUser != null;

//   Future<void> _onAuthStateChanged(User? user) async {
//     _firebaseUser = user;
//     if (user != null) {
//       _isLoading = true;
//       notifyListeners();
//       _userModel = await _userRepository.getUser(user.uid);
//       _isLoading = false;
//     } else {
//       _userModel = null;
//     }
//     notifyListeners();
//   }

//   Future<void> signInWithEmail(String email, String password) async {
//     try {
//       _isLoading = true;
//       notifyListeners();
//       await _authRepository.signInWithEmail(email, password);
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signUpWithEmail(
//     String email,
//     String password,
//     String name,
//   ) async {
//     try {
//       _isLoading = true;
//       notifyListeners();
//       final credential = await _authRepository.signUpWithEmail(email, password);

//       if (credential != null && credential.user != null) {
//         final newUser = UserModel(
//           id: credential.user!.uid,
//           email: email,
//           displayName: name,
//           trialStartDate: DateTime.now(),
//           isPremium: false,
//           dailyConversionCount: 0,
//           lastConversionDate: DateTime.now(),
//         );
//         await _userRepository.createUser(newUser);
//         _userModel = newUser;
//       }
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signInWithGoogle() async {
//     try {
//       _isLoading = true;
//       notifyListeners();
//       final credential = await _authRepository.signInWithGoogle();

//       if (credential != null && credential.user != null) {
//         // Check if user exists in Firestore, if not create
//         final existingUser = await _userRepository.getUser(
//           credential.user!.uid,
//         );
//         if (existingUser == null) {
//           final newUser = UserModel(
//             id: credential.user!.uid,
//             email: credential.user!.email ?? '',
//             displayName: credential.user!.displayName,
//             photoUrl: credential.user!.photoURL,
//             trialStartDate: DateTime.now(),
//             isPremium: false,
//             dailyConversionCount: 0,
//             lastConversionDate: DateTime.now(),
//           );
//           await _userRepository.createUser(newUser);
//           _userModel = newUser;
//         }
//       }
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signOut() async {
//     await _authRepository.signOut();
//   }

//   Future<void> sendPasswordResetEmail(String email) async {
//     await _authRepository.sendPasswordResetEmail(email);
//   }

//   Future<bool> checkAndIncrementLimit() async {
//     final now = DateTime.now();

//     // 1. Handle Guest User (Not Logged In)
//     if (_userModel == null) {
//       bool isNewDay =
//           _lastGuestConversionDate.day != now.day ||
//           _lastGuestConversionDate.month != now.month ||
//           _lastGuestConversionDate.year != now.year;

//       if (isNewDay) {
//         _guestConversionCount = 0;
//         _lastGuestConversionDate = now;
//       }

//       if (_guestConversionCount < 5) {
//         _guestConversionCount++;
//         notifyListeners();
//         return true;
//       }
//       return false;
//     }

//     // 2. Handle Authenticated User
//     if (_userModel!.hasPremiumAccess) {
//       // Premium users/Trial users don't have limits
//       await _userRepository.incrementConversionCount(_userModel!.id);
//       _userModel = await _userRepository.getUser(_userModel!.id);
//       notifyListeners();
//       return true;
//     }

//     // Check 5-per-day limit for free users
//     bool isNewDay =
//         _userModel!.lastConversionDate.day != now.day ||
//         _userModel!.lastConversionDate.month != now.month ||
//         _userModel!.lastConversionDate.year != now.year;

//     int currentCount = isNewDay ? 0 : _userModel!.dailyConversionCount;

//     if (currentCount < 5) {
//       await _userRepository.incrementConversionCount(_userModel!.id);
//       _userModel = await _userRepository.getUser(_userModel!.id);
//       notifyListeners();
//       return true;
//     }

//     return false;
//   }
// }
