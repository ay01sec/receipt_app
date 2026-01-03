import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../providers/store_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../receipt/receipt_detail_screen.dart';

class CreateReceiptScreen extends ConsumerStatefulWidget {
  const CreateReceiptScreen({super.key});

  @override
  ConsumerState<CreateReceiptScreen> createState() =>
      _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends ConsumerState<CreateReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _memoController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _subtotalAmountController = TextEditingController();

  double _selectedTaxRate = TaxRates.standard;
  bool _isCalculatingFromTotal = true;

  @override
  void dispose() {
    _recipientNameController.dispose();
    _memoController.dispose();
    _totalAmountController.dispose();
    _subtotalAmountController.dispose();
    super.dispose();
  }

  void _initializeDefaultMemo(String defaultMemo) {
    if (_memoController.text.isEmpty && defaultMemo.isNotEmpty) {
      _memoController.text = defaultMemo;
    }
  }

  void _calculateAmounts() {
    if (_isCalculatingFromTotal) {
      // 税込金額から税抜金額を計算
      final total = Validators.parseAmount(_totalAmountController.text);
      if (total != null) {
        final subtotal = TaxRates.calculateSubtotal(total, _selectedTaxRate);
        _subtotalAmountController.text = Formatters.formatAmount(subtotal);
      }
    } else {
      // 税抜金額から税込金額を計算
      final subtotal = Validators.parseAmount(_subtotalAmountController.text);
      if (subtotal != null) {
        final total = TaxRates.calculateTotal(subtotal, _selectedTaxRate);
        _totalAmountController.text = Formatters.formatAmount(total);
      }
    }
  }

  Future<void> _createReceipt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final storeState = ref.read(storeControllerProvider);
    final store = storeState.value;

    if (store == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('店舗情報が設定されていません。設定画面から店舗情報を登録してください。'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ローディングダイアログを表示
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('領収書を作成中...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 印鑑画像を取得
      Uint8List? stampImageBytes;
      if (store.stampImageUrl != null) {
        try {
          final response = await http.get(Uri.parse(store.stampImageUrl!));
          if (response.statusCode == 200) {
            stampImageBytes = response.bodyBytes;
          }
        } catch (e) {
          // 印鑑画像の取得に失敗してもエラーにしない
        }
      }

      final totalAmount = Validators.parseAmount(_totalAmountController.text)!;
      final recipientName = _recipientNameController.text.trim();

      // 宛名が空の場合は空文字列、そうでない場合は「様」を付ける
      final formattedRecipientName = recipientName.isEmpty
          ? ''
          : (recipientName.endsWith('様') ? recipientName : '$recipientName 様');

      final receiptController = ref.read(receiptControllerProvider.notifier);
      final receipt = await receiptController.createReceipt(
        store: store,
        recipientName: formattedRecipientName,
        memo: _memoController.text.trim(),
        totalAmount: totalAmount,
        taxRate: _selectedTaxRate,
        stampImageBytes: stampImageBytes,
      );

      // ローディングダイアログを閉じる
      if (mounted) Navigator.of(context).pop();

      if (receipt != null && mounted) {
      // 成功ダイアログを表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: UIConstants.paddingSmall),
              Text('成功'),
            ],
          ),
          content: Text('領収書No ${receipt.receiptNumber} を保存しました'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 領収書詳細画面に遷移
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReceiptDetailScreen(
                      userId: store.userId,
                      storeId: store.id,
                      receiptId: receipt.id,
                    ),
                  ),
                );
                // フォームをクリア
                _formKey.currentState!.reset();
                _recipientNameController.clear();
                _memoController.text = store.defaultMemo;
                _totalAmountController.clear();
                _subtotalAmountController.clear();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
      } else if (mounted) {
        // エラー表示
        final error = ref.read(receiptControllerProvider).error;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: UIConstants.paddingSmall),
              Text('失敗'),
            ],
          ),
          content: Text(error?.toString() ?? 'エラーが発生しました'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createReceipt();
              },
              child: const Text('リトライ'),
            ),
          ],
        ),
        );
      }
    } catch (e) {
      // エラーが発生した場合もローディングダイアログを閉じる
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: UIConstants.paddingSmall),
                Text('エラー'),
              ],
            ),
            content: Text('予期しないエラーが発生しました: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('トップ画面'),
      ),
      body: storeState.when(
        data: (store) {
          if (store != null) {
            _initializeDefaultMemo(store.defaultMemo);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (store == null)
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(UIConstants.paddingMedium),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: UIConstants.paddingSmall),
                            Expanded(
                              child: Text(
                                '店舗情報が未設定です。設定画面から登録してください。',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 宛名
                  TextFormField(
                    controller: _recipientNameController,
                    decoration: const InputDecoration(
                      labelText: '宛名（任意）',
                      prefixIcon: Icon(Icons.person),
                      hintText: '〇〇株式会社',
                    ),
                    validator: Validators.validateRecipientName,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 但し書き
                  TextFormField(
                    controller: _memoController,
                    decoration: const InputDecoration(
                      labelText: '但し書き',
                      prefixIcon: Icon(Icons.description),
                      hintText: '〇〇代として',
                    ),
                    validator: Validators.validateMemo,
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 税率選択
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(UIConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '税率',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<double>(
                                  title: const Text('10%（標準）'),
                                  value: TaxRates.standard,
                                  groupValue: _selectedTaxRate,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTaxRate = value!;
                                      _calculateAmounts();
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<double>(
                                  title: const Text('8%（軽減）'),
                                  value: TaxRates.reduced,
                                  groupValue: _selectedTaxRate,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTaxRate = value!;
                                      _calculateAmounts();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 税込合計金額
                  TextFormField(
                    controller: _totalAmountController,
                    decoration: const InputDecoration(
                      labelText: '税込合計金額',
                      prefixIcon: Icon(Icons.attach_money),
                      suffixText: '円',
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateAmount,
                    onChanged: (value) {
                      _isCalculatingFromTotal = true;
                      _calculateAmounts();
                    },
                  ),
                  const SizedBox(height: UIConstants.paddingMedium),

                  // 税抜合計金額
                  TextFormField(
                    controller: _subtotalAmountController,
                    decoration: const InputDecoration(
                      labelText: '税抜合計金額',
                      prefixIcon: Icon(Icons.money_off),
                      suffixText: '円',
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateAmount,
                    onChanged: (value) {
                      _isCalculatingFromTotal = false;
                      _calculateAmounts();
                    },
                  ),
                  const SizedBox(height: UIConstants.paddingLarge * 2),

                  // 領収書作成ボタン
                  ElevatedButton.icon(
                    onPressed: store == null ? null : _createReceipt,
                    icon: const Icon(Icons.receipt),
                    label: const Text('領収書作成'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: UIConstants.paddingLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}
