// I keep all Firebase Auth calls in one place so screens never touch
// FirebaseAuth directly. Makes it easy to swap the auth provider later.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  // Apple Sign In -- bypasses the Firebase Apple provider (which fails with
  // invalid-credential for native iOS tokens) by verifying the Apple identity
  // token in a Cloud Function and returning a Firebase custom auth token.
  Future<({UserCredential credential, bool isNewUser})> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = appleCredential.identityToken;
    if (identityToken == null) {
      throw Exception('Apple Sign In did not return an identity token');
    }

    final result = await _functions
        .httpsCallable('verifyAppleToken')
        .call<Map<String, dynamic>>({'identityToken': identityToken});

    final customToken = result.data['customToken'] as String;
    final isNewUser = result.data['isNewUser'] as bool? ?? false;

    final userCredential = await _auth.signInWithCustomToken(customToken);
    return (credential: userCredential, isNewUser: isNewUser);
  }
}
