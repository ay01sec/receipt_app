import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/auth_repository.dart';
import '../models/user_data.dart';
import '../utils/constants.dart';

/// AuthRepositoryのプロバイダー
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 認証状態を監視するStreamProvider
final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// 現在のユーザーを取得するProvider
final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final user = authRepository.currentUser;
  print('🔵 currentUserProvider: user = ${user?.uid ?? "null"}');
  return user;
});

/// 現在のユーザーのUserDataを取得するStreamProvider
final userDataProvider = StreamProvider<UserData?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }

      final firestore = FirebaseFirestore.instance;
      return firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }
        return UserData.fromFirestore(snapshot);
      });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// 認証コントローラー（認証関連の操作を行う）
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  /// ログイン
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _authRepository.currentUser;
      print('🟢 AuthController: User signed in - uid: ${user?.uid}, email: ${user?.email}');
    });

    if (state.hasError) {
      print('🔴 AuthController: Sign in error: ${state.error}');
    }
  }

  /// アカウント作成
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.sendPasswordResetEmail(email: email);
    });
  }

  /// パスワード変更
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    });
  }

  /// ログアウト
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
    });
  }

  /// アカウント削除
  Future<void> deleteAccount({required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.deleteAccount(password: password);
    });
  }
}

/// AuthControllerのプロバイダー
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});
