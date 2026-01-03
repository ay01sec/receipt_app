import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  // Flutterのバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // アプリを起動
  runApp(
    // Riverpodを使用するためProviderScopeでラップ
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'NotoSansJP',
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.paddingLarge,
              vertical: UIConstants.paddingMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
            ),
          ),
        ),
      ),
      // 認証状態によってルーティングを変更
      home: const AuthWrapper(),
    );
  }
}

/// 認証状態に応じて画面を切り替えるラッパー
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // ログイン済み - 後でホーム画面に変更
          return const PlaceholderHomeScreen();
        } else {
          // 未ログイン - ログイン画面を表示
          return const LoginScreen();
        }
      },
      loading: () => const SplashScreen(),
      error: (error, stack) {
        // エラー時はログイン画面を表示
        return const LoginScreen();
      },
    );
  }
}

/// スプラッシュスクリーン（初期化中に表示）
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

/// プレースホルダーのホーム画面（後で実装）
class PlaceholderHomeScreen extends ConsumerWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authController = ref.read(authControllerProvider.notifier);
              await authController.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            const Text(
              'ログイン成功！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'メール: ${user?.email ?? ""}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            const Text(
              '※ホーム画面は後で実装します',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
