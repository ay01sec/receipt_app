import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    await authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // エラーチェック
    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      error: (error, stack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // アプリアイコン
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // アプリ名
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge * 2),

                  // メールアドレス入力
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: Validators.validateEmail,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // パスワード入力
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: Validators.validatePassword,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // ログインボタン
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ログイン'),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // パスワードリセットリンク
                  TextButton(
                    onPressed: isLoading ? null : _showPasswordResetDialog,
                    child: const Text('パスワードをお忘れの方'),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // 区切り線
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: UIConstants.paddingMedium,
                        ),
                        child: Text('または'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // アカウント作成ボタン
                  OutlinedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text('アカウントを作成'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPasswordResetDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワードリセット'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('登録したメールアドレスを入力してください。\nパスワードリセット用のメールを送信します。'),
            const SizedBox(height: UIConstants.paddingMedium),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                return;
              }

              Navigator.of(context).pop();

              final authController = ref.read(authControllerProvider.notifier);
              await authController.sendPasswordResetEmail(email: email);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('パスワードリセットメールを送信しました'),
                  ),
                );
              }
            },
            child: const Text('送信'),
          ),
        ],
      ),
    );
  }
}
