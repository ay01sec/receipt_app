import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/store_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import 'receipt_detail_screen.dart';

class ReceiptListScreen extends ConsumerStatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  ConsumerState<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends ConsumerState<ReceiptListScreen> {
  final _recipientNameController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _recipientNameController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _clearFilters(String storeId) {
    _recipientNameController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    setState(() {
      _selectedDateRange = null;
    });

    // 検索をリセット
    ref.read(receiptSearchControllerProvider(storeId).notifier).refresh();
  }

  void _search(String storeId) {
    final minAmount = Validators.parseAmount(_minAmountController.text);
    final maxAmount = Validators.parseAmount(_maxAmountController.text);

    ref.read(receiptSearchControllerProvider(storeId).notifier).searchReceipts(
          startDate: _selectedDateRange?.start,
          endDate: _selectedDateRange?.end,
          recipientName: _recipientNameController.text.trim().isNotEmpty
              ? _recipientNameController.text.trim()
              : null,
          minAmount: minAmount,
          maxAmount: maxAmount,
        );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('作成履歴'),
      ),
      body: storeState.when(
        data: (store) {
          if (store == null) {
            return const Center(
              child: Text('店舗情報が設定されていません'),
            );
          }

          final receiptsState =
              ref.watch(receiptSearchControllerProvider(store.id));

          return Column(
            children: [
              // 検索フィルター
              ExpansionTile(
                title: const Text('検索フィルター'),
                leading: const Icon(Icons.filter_list),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(UIConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 日付範囲
                        OutlinedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            _selectedDateRange == null
                                ? '日付範囲を選択'
                                : '${Formatters.formatDateSlash(_selectedDateRange!.start)} 〜 ${Formatters.formatDateSlash(_selectedDateRange!.end)}',
                          ),
                        ),
                        const SizedBox(height: UIConstants.paddingSmall),

                        // 宛名
                        TextField(
                          controller: _recipientNameController,
                          decoration: const InputDecoration(
                            labelText: '宛名',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: UIConstants.paddingSmall),

                        // 金額範囲
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _minAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '最小金額',
                                  prefixIcon: Icon(Icons.attach_money),
                                  suffixText: '円',
                                ),
                              ),
                            ),
                            const SizedBox(width: UIConstants.paddingSmall),
                            const Text('〜'),
                            const SizedBox(width: UIConstants.paddingSmall),
                            Expanded(
                              child: TextField(
                                controller: _maxAmountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '最大金額',
                                  suffixText: '円',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: UIConstants.paddingMedium),

                        // ボタン
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _clearFilters(store.id),
                                child: const Text('クリア'),
                              ),
                            ),
                            const SizedBox(width: UIConstants.paddingSmall),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _search(store.id),
                                child: const Text('検索'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),

              // 領収書リスト
              Expanded(
                child: receiptsState.when(
                  data: (receipts) {
                    if (receipts.isEmpty) {
                      return const Center(
                        child: Text('領収書がありません'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(receiptSearchControllerProvider(store.id)
                                .notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        itemCount: receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = receipts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: UIConstants.paddingMedium,
                              vertical: UIConstants.paddingSmall,
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.receipt),
                              ),
                              title: Text(receipt.recipientName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No: ${receipt.receiptNumber}'),
                                  Text(receipt.issueDateString),
                                ],
                              ),
                              trailing: Text(
                                '¥${Formatters.formatAmount(receipt.totalAmount)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReceiptDetailScreen(
                                      storeId: store.id,
                                      receiptId: receipt.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                            ref
                                .read(receiptSearchControllerProvider(store.id)
                                    .notifier)
                                .refresh();
                          },
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
