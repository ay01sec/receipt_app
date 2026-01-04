import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// チュートリアル画面
class TutorialScreen extends StatefulWidget {
  /// 完了時のコールバック（オプション）
  final VoidCallback? onComplete;

  const TutorialScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialPage> _pages = [
    _TutorialPage(
      title: 'ReceiptQRへようこそ',
      description: 'スマホで簡単に領収書を作成できるアプリです。\n'
          'このチュートリアルでは、基本的な使い方をご説明します。',
      icon: Icons.receipt_long,
      iconColor: Colors.blue,
    ),
    _TutorialPage(
      title: '1. 店舗情報を登録',
      description: '最初に設定画面から店舗情報を登録しましょう。\n\n'
          '• 店舗名\n'
          '• 住所\n'
          '• 電話番号\n'
          '• インボイス番号\n'
          '• 店舗印鑑画像（オプション）\n\n'
          'これらの情報は領収書に自動的に印字されます。',
      icon: Icons.store,
      iconColor: Colors.green,
    ),
    _TutorialPage(
      title: '2. 領収書を作成',
      description: 'ホーム画面の「+」ボタンから領収書を作成できます。\n\n'
          '必要な情報：\n'
          '• 宛名（受取人名）\n'
          '• 金額\n'
          '• 但し書き\n'
          '• 税率（8%または10%）\n\n'
          '入力後、「作成」ボタンでPDFが自動生成されます。',
      icon: Icons.edit_document,
      iconColor: Colors.orange,
    ),
    _TutorialPage(
      title: '3. PDFとQRコード',
      description: '作成された領収書はPDF形式で保存されます。\n\n'
          'QRコードをスキャンすると、PDF URLに直接アクセスできます。\n\n'
          '• 共有ボタンでメールやLINEで送信\n'
          '• ダウンロードして印刷\n'
          '• クラウドに自動保存',
      icon: Icons.qr_code_2,
      iconColor: Colors.purple,
    ),
    _TutorialPage(
      title: '4. プレミアムプラン',
      description: 'プレミアムプランで全機能をご利用いただけます。\n\n'
          '• 3日間無料トライアル\n'
          '• 月額プラン: ¥500/月\n'
          '• 年額プラン: ¥5,000/年（2ヶ月分お得）\n\n'
          '設定画面の「プレミアムプラン」から登録できます。',
      icon: Icons.workspace_premium,
      iconColor: Colors.amber,
    ),
    _TutorialPage(
      title: '準備完了！',
      description: '以上でチュートリアルは終了です。\n\n'
          '設定画面の「使い方」からいつでもこのチュートリアルを確認できます。\n\n'
          'それでは、領収書作成を始めましょう！',
      icon: Icons.check_circle,
      iconColor: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _complete() {
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('使い方'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _complete,
            child: const Text('スキップ'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ページインジケーター
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UIConstants.paddingLarge,
              vertical: UIConstants.paddingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ページビュー
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _TutorialPageView(page: page);
              },
            ),
          ),

          // ナビゲーションボタン
          Padding(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 戻るボタン
                if (_currentPage > 0)
                  OutlinedButton(
                    onPressed: _previousPage,
                    child: const Text('戻る'),
                  )
                else
                  const SizedBox(width: 80),

                // 進む/完了ボタン
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _pages.length - 1 ? '完了' : '次へ',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// チュートリアルページのデータモデル
class _TutorialPage {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;

  _TutorialPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
  });
}

/// チュートリアルページビュー
class _TutorialPageView extends StatelessWidget {
  final _TutorialPage page;

  const _TutorialPageView({
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // アイコン
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.iconColor,
            ),
          ),
          const SizedBox(height: UIConstants.paddingLarge * 2),

          // タイトル
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: UIConstants.paddingLarge),

          // 説明文
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
