import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/tutorial/tutorial_screen.dart';
import 'services/revenue_cat_service.dart';

void main() async {
  // Flutterのバインディングを初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境変数を読み込む
  try {
    await dotenv.load(fileName: '.env');
    // .envからRevenueCat APIキーを読み込んでRevenueCatConfigに設定
    final apiKey = dotenv.env['REVENUECAT_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'YOUR_API_KEY_HERE') {
      RevenueCatConfig.apiKey = apiKey;
      debugPrint('✅ RevenueCat APIキーを.envから読み込みました');
    } else {
      debugPrint('⚠️ RevenueCat APIキーが.envに設定されていません');
    }
  } catch (e) {
    debugPrint('⚠️ .envファイルの読み込みに失敗しました: $e');
  }

  // Firebaseを初期化（既に初期化済みの場合はスキップ）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // 既に初期化済みの場合はエラーを無視
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase is already initialized');
    } else {
      rethrow;
    }
  }

  // RevenueCatを初期化
  try {
    await RevenueCatService.initialize(
      apiKey: RevenueCatConfig.apiKey,
    );
  } catch (e) {
    // RevenueCat初期化エラーはログのみ（アプリは起動する）
    debugPrint('RevenueCat初期化エラー: $e');
  }

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
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isFirstLaunch = true;
  bool _isCheckingFirstLaunch = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  /// 初回起動かどうかをチェック
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('has_seen_tutorial') ?? false;

    setState(() {
      _isFirstLaunch = !hasSeenTutorial;
      _isCheckingFirstLaunch = false;
    });
  }

  /// チュートリアル完了時の処理
  Future<void> _onTutorialComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_tutorial', true);

    setState(() {
      _isFirstLaunch = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 初回起動チェック中はスプラッシュ表示
    if (_isCheckingFirstLaunch) {
      return const SplashScreen();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // ログイン済み - ユーザーデータをチェック
          final userDataState = ref.watch(userDataProvider);

          return userDataState.when(
            data: (userData) {
              if (userData == null) {
                // ユーザーデータが見つからない場合はスプラッシュ表示
                return const SplashScreen();
              }

              // トライアル期間が終了し、サブスクリプションもない場合
              if (userData.shouldShowPaywall) {
                // 課金画面を強制表示（戻るボタン無効）
                return const SubscriptionScreen(isRequired: true);
              }

              // トライアル中 or サブスクリプション有効 - メインナビゲーション表示
              return const MainNavigation();
            },
            loading: () => const SplashScreen(),
            error: (error, stack) {
              debugPrint('⚠️ UserData取得エラー: $error');
              // エラー時もメインナビゲーションを表示
              return const MainNavigation();
            },
          );
        } else {
          // 未ログイン - 初回起動時はチュートリアル表示
          if (_isFirstLaunch) {
            return TutorialScreen(
              onComplete: _onTutorialComplete,
            );
          }

          // 2回目以降はログイン画面を表示
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

