import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// 인증 예외를 사용자에게 보여줄 한국어 메시지로 바꾼다.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return '이메일 형식이 올바르지 않아요.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않아요.';
      case 'email-already-in-use':
        return '이미 가입된 이메일이에요.';
      case 'weak-password':
        return '비밀번호는 6자 이상으로 입력해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return error.message ?? '문제가 발생했어요. 다시 시도해주세요.';
    }
  }
  return '로그인에 실패했어요. 다시 시도해주세요.';
}

/// 앱 내부에서 쓰는 최소 사용자 모델. (Firebase User를 감싸 UI가 SDK에 직접 의존하지 않게)
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

/// 인증 경계 인터페이스. 구현을 갈아끼우거나 테스트에서 가짜로 주입할 수 있다.
abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signInWithEmail({required String email, required String password});
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signInWithGoogle();
  Future<void> signOut();
}

/// Firebase Auth + Google 로그인 구현.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _googleInitialized = false;

  AppUser? _map(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await credential.user?.reload();
  }

  @override
  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } on Object {
      // Google 세션이 없어도 무시.
    }
    await _auth.signOut();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final serverClientId = dotenv.isInitialized
        ? dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim()
        : null;
    await GoogleSignIn.instance.initialize(
      serverClientId: (serverClientId != null && serverClientId.isNotEmpty)
          ? serverClientId
          : null,
    );
    _googleInitialized = true;
  }
}
