import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    await authController.createAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // エラーチェック
    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      data: (_) {
        // アカウント作成成功
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(SuccessMessages.accountCreated),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
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
      appBar: AppBar(
        title: const Text('アカウント作成'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // アイコン
                  Icon(
                    Icons.person_add,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // タイトル
                  Text(
                    '新しいアカウントを作成',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      helperText: 'ログイン時に使用します',
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
                      helperText: '8文字以上で入力してください',
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
                  const SizedBox(height: UIConstants.paddingMedium),

                  // パスワード確認入力
                  TextFormField(
                    controller: _passwordConfirmController,
                    obscureText: _obscurePasswordConfirm,
                    decoration: InputDecoration(
                      labelText: 'パスワード（確認）',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePasswordConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePasswordConfirm = !_obscurePasswordConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) => Validators.validatePasswordConfirmation(
                      value,
                      _passwordController.text,
                    ),
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: UIConstants.paddingLarge * 2),

                  // アカウント作成ボタン
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleRegister,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('アカウントを作成'),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 利用規約とプライバシーポリシー
                  Text(
                    'アカウントを作成することで、利用規約とプライバシーポリシーに同意したものとみなされます。',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
