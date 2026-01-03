import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _phoneController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _defaultMemoController = TextEditingController();

  String? _selectedImagePath;
  bool _isInitialized = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _phoneController.dispose();
    _invoiceNumberController.dispose();
    _defaultMemoController.dispose();
    super.dispose();
  }

  void _initializeForm(store) {
    if (_isInitialized || store == null) return;

    _storeNameController.text = store.storeName;
    _address1Controller.text = store.storeAddress1;
    _address2Controller.text = store.storeAddress2;
    _phoneController.text = store.phoneNumber;
    _invoiceNumberController.text = store.invoiceNumber;
    _defaultMemoController.text = store.defaultMemo;

    _isInitialized = true;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  Future<void> _saveStore() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storeController = ref.read(storeControllerProvider.notifier);
    final currentStore = ref.read(storeControllerProvider).value;

    if (currentStore == null) {
      // 新規作成
      await storeController.createStore(
        storeName: _storeNameController.text.trim(),
        storeAddress1: _address1Controller.text.trim(),
        storeAddress2: _address2Controller.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim(),
        defaultMemo: _defaultMemoController.text.trim(),
        stampImagePath: _selectedImagePath,
      );
    } else {
      // 更新
      await storeController.updateStore(
        storeId: currentStore.id,
        storeName: _storeNameController.text.trim(),
        storeAddress1: _address1Controller.text.trim(),
        storeAddress2: _address2Controller.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        invoiceNumber: _invoiceNumberController.text.trim(),
        defaultMemo: _defaultMemoController.text.trim(),
        stampImagePath: _selectedImagePath,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(SuccessMessages.storeSaved),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final storeState = ref.watch(storeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: storeState.when(
        data: (store) {
          _initializeForm(store);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ログイン中のメールアドレス（読み取り専用）
                  TextFormField(
                    initialValue: user?.email ?? '',
                    decoration: const InputDecoration(
                      labelText: 'ログイン用メールアドレス',
                      prefixIcon: Icon(Icons.email),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 店舗名
                  TextFormField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(
                      labelText: '店舗名',
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: Validators.validateStoreName,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 住所1
                  TextFormField(
                    controller: _address1Controller,
                    decoration: const InputDecoration(
                      labelText: '店舗住所1',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: Validators.validateAddress,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 住所2
                  TextFormField(
                    controller: _address2Controller,
                    decoration: const InputDecoration(
                      labelText: '店舗住所2（任意）',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) =>
                        Validators.validateAddress(value, required: false),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 電話番号
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '電話番号',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '03-1234-5678',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhoneNumber,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // インボイス番号
                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(
                      labelText: 'インボイス番号',
                      prefixIcon: Icon(Icons.numbers),
                      hintText: 'T1234567890123',
                    ),
                    validator: (value) =>
                        Validators.validateInvoiceNumber(value, required: false),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 但し書きデフォルト値
                  TextFormField(
                    controller: _defaultMemoController,
                    decoration: const InputDecoration(
                      labelText: '但し書きのデフォルト値',
                      prefixIcon: Icon(Icons.description),
                      hintText: '〇〇代として',
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // 印鑑画像
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '店舗印鑑画像',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: UIConstants.paddingSmall),
                          if (_selectedImagePath != null ||
                              store?.stampImageUrl != null)
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(
                                  UIConstants.borderRadiusSmall,
                                ),
                              ),
                              child: _selectedImagePath != null
                                  ? Image.network(_selectedImagePath!)
                                  : (store?.stampImageUrl != null
                                      ? Image.network(store!.stampImageUrl!)
                                      : null),
                            ),
                          const SizedBox(height: UIConstants.paddingSmall),
                          OutlinedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: Text(
                              _selectedImagePath != null || store?.stampImageUrl != null
                                  ? '画像を変更'
                                  : '画像を選択',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // 保存ボタン
                  ElevatedButton(
                    onPressed: _saveStore,
                    child: const Text('保存'),
                  ),
                  const SizedBox(height: UIConstants.paddingLarge),

                  // パスワード変更リンク
                  TextButton.icon(
                    onPressed: _showPasswordChangeDialog,
                    icon: const Icon(Icons.lock),
                    label: const Text('パスワードを変更'),
                  ),

                  // ログアウトボタン
                  TextButton.icon(
                    onPressed: () async {
                      final authController =
                          ref.read(authControllerProvider.notifier);
                      await authController.signOut();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ログアウト'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: UIConstants.paddingMedium),
              Text('エラー: $error'),
              const SizedBox(height: UIConstants.paddingMedium),
              ElevatedButton(
                onPressed: () {
                  ref.read(storeControllerProvider.notifier).refresh();
                },
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordChangeDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('パスワード変更'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '現在のパスワード',
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: UIConstants.paddingMedium),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新しいパスワード',
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: UIConstants.paddingMedium),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '新しいパスワード（確認）',
                ),
                validator: (value) =>
                    Validators.validatePasswordConfirmation(
                  value,
                  newPasswordController.text,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              Navigator.of(context).pop();

              final authController =
                  ref.read(authControllerProvider.notifier);
              await authController.changePassword(
                currentPassword: currentPasswordController.text,
                newPassword: newPasswordController.text,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(SuccessMessages.passwordChanged),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }
}
