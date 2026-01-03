import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// 認証に関するビジネスロジックを管理するリポジトリ
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  /// 認証状態の変化を監視するStream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// メールアドレスとパスワードでログイン
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ログインに失敗しました');
      }

      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('ログインに失敗しました: ${e.toString()}');
    }
  }

  /// メールアドレスとパスワードでアカウント作成
  Future<User> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('アカウント作成に失敗しました');
      }

      final user = userCredential.user!;

      // Firestoreにユーザー情報を保存
      await _createUserDocument(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('アカウント作成に失敗しました: ${e.toString()}');
    }
  }

  /// Firestoreにユーザードキュメントを作成
  Future<void> _createUserDocument(User user) async {
    final now = Timestamp.now();
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set({
      'email': user.email,
      'createdAt': now,
      'updatedAt': now,
      'subscriptionPlan': null,
      'subscriptionStatus': null,
      'subscriptionStartDate': null,
      'subscriptionEndDate': null,
      'autoRenew': null,
    });
  }

  /// パスワードリセットメールを送信
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('パスワードリセットメールの送信に失敗しました: ${e.toString()}');
    }
  }

  /// パスワードを変更
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 現在のパスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 新しいパスワードに変更
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('パスワードの変更に失敗しました: ${e.toString()}');
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('ログアウトに失敗しました: ${e.toString()}');
    }
  }

  /// アカウントを削除
  Future<void> deleteAccount({required String password}) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Firestoreのユーザーデータを削除
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .delete();

      // アカウントを削除
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('アカウントの削除に失敗しました: ${e.toString()}');
    }
  }

  /// FirebaseAuthExceptionをユーザーフレンドリーなメッセージに変換
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return '無効なメールアドレスです';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'network-request-failed':
        return ErrorMessages.networkError;
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってから再試行してください';
      case 'requires-recent-login':
        return 'この操作には再ログインが必要です';
      default:
        return e.message ?? ErrorMessages.unknownError;
    }
  }
}
