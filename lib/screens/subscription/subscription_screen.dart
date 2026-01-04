import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/subscription_provider.dart';
import '../../utils/constants.dart';

/// サブスクリプション購入画面
class SubscriptionScreen extends ConsumerStatefulWidget {
  /// トライアル終了後の強制表示かどうか
  final bool isRequired;

  const SubscriptionScreen({
    super.key,
    this.isRequired = false,
  });

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  String? _errorMessage;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  /// Offerings を読み込む
  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final controller = ref.read(subscriptionControllerProvider.notifier);
      final offerings = await controller.getOfferings();

      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'プラン情報の取得に失敗しました: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// 購入処理
  Future<void> _purchase() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プランを選択してください')),
      );
      return;
    }

    final controller = ref.read(subscriptionControllerProvider.notifier);

    try {
      final success = await controller.purchase(_selectedPackage!);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入が完了しました！')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入に失敗しました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: ${e.toString()}')),
      );
    }
  }

  /// 購入をリストア
  Future<void> _restore() async {
    final controller = ref.read(subscriptionControllerProvider.notifier);

    try {
      final success = await controller.restorePurchases();

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('購入情報を復元しました')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('復元する購入情報が見つかりませんでした')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // 強制表示の場合は戻るボタンを無効化
      onWillPop: () async => !widget.isRequired,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('プレミアムプラン'),
          // 強制表示の場合は戻るボタンを非表示
          automaticallyImplyLeading: !widget.isRequired,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
      ),
    );
  }

  /// エラー表示
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: UIConstants.paddingLarge),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  /// メインコンテンツ
  Widget _buildContent() {
    final currentOffering = _offerings?.current;
    if (currentOffering == null) {
      return const Center(
        child: Text('利用可能なプランがありません'),
      );
    }

    // 月額・年額パッケージを取得
    final monthlyPackage = currentOffering.monthly;
    final annualPackage = currentOffering.annual;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ヘッダー
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: UIConstants.paddingMedium),
            Text(
              'プレミアムプランで\nすべての機能を使い放題',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: UIConstants.paddingLarge),

            // 機能一覧
            _buildFeatureItem('無制限の領収書作成'),
            _buildFeatureItem('クラウドに安全に保存'),
            _buildFeatureItem('複数デバイスで同期'),
            _buildFeatureItem('PDF自動生成・送信'),
            _buildFeatureItem('印鑑画像の登録'),
            const SizedBox(height: UIConstants.paddingLarge),

            // プラン選択
            if (monthlyPackage != null)
              _buildPlanCard(
                package: monthlyPackage,
                title: '月額プラン',
                isSelected: _selectedPackage?.identifier == monthlyPackage.identifier,
              ),
            const SizedBox(height: UIConstants.paddingMedium),
            if (annualPackage != null)
              _buildPlanCard(
                package: annualPackage,
                title: '年額プラン',
                subtitle: 'お得！',
                isSelected: _selectedPackage?.identifier == annualPackage.identifier,
                isRecommended: true,
              ),
            const SizedBox(height: UIConstants.paddingLarge),

            // 購入ボタン
            ElevatedButton(
              onPressed: _selectedPackage != null ? _purchase : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _selectedPackage != null ? '購入する' : 'プランを選択してください',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: UIConstants.paddingMedium),

            // リストアボタン
            TextButton(
              onPressed: _restore,
              child: const Text('購入情報を復元'),
            ),
            const SizedBox(height: UIConstants.paddingSmall),

            // 注意書き
            Text(
              '※ 購入は自動的に更新されます。\n※ キャンセルはApp Storeの設定から行えます。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 機能アイテム
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// プランカード
  Widget _buildPlanCard({
    required Package package,
    required String title,
    String? subtitle,
    required bool isSelected,
    bool isRecommended = false,
  }) {
    final product = package.storeProduct;
    final price = product.priceString;
    final period = package.packageType == PackageType.monthly ? '月' : '年';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(UIConstants.borderRadiusMedium),
          color: isRecommended ? Colors.blue.shade50 : Colors.white,
        ),
        padding: const EdgeInsets.all(UIConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // ラジオボタン
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                // タイトル
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$price / $period',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
