import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../providers/receipt_provider.dart';
import '../../services/qr_service.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String userId;
  final String storeId;
  final String receiptId;

  const ReceiptDetailScreen({
    super.key,
    required this.userId,
    required this.storeId,
    required this.receiptId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptState = ref.watch(
      receiptDetailProvider(
        ReceiptParams(userId: userId, storeId: storeId, receiptId: receiptId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('領収書詳細'),
        actions: [
          receiptState.when(
            data: (receipt) {
              if (receipt == null) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async {
                  if (receipt.pdfUrl != null) {
                    await Share.shareUri(
                      Uri.parse(receipt.pdfUrl!),
                    );
                  }
                },
              );
            },
            loading: () => const SizedBox(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
      body: receiptState.when(
        data: (receipt) {
          if (receipt == null) {
            return const Center(child: Text('領収書が見つかりません'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(UIConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // QRコード（タップでPDF表示）
                Center(
                  child: GestureDetector(
                    onTap: receipt.pdfUrl != null
                        ? () => _showPdfModal(context, receipt.pdfUrl!)
                        : null,
                    child: Column(
                      children: [
                        QrService.generateQrWidget(
                          data: receipt.qrCodeData,
                          size: 150,
                        ),
                        if (receipt.pdfUrl != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'タップして領収書を表示',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.paddingLarge),

                // 領収書情報カード
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(UIConstants.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('領収書No', receipt.receiptNumber),
                        const Divider(),
                        _buildInfoRow('発行日', receipt.issueDateString),
                        const Divider(),
                        _buildInfoRow('宛名', receipt.recipientName),
                        const Divider(),
                        _buildInfoRow('但し書き', receipt.memo),
                        const Divider(),
                        _buildInfoRow(
                          '税込金額',
                          '¥${Formatters.formatAmount(receipt.totalAmount)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          '税抜金額',
                          '¥${Formatters.formatAmount(receipt.subtotalAmount)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          '消費税（${receipt.taxRate.toStringAsFixed(0)}%）',
                          '¥${Formatters.formatAmount(receipt.taxAmount)}',
                        ),
                        const Divider(),
                        _buildInfoRow(
                          'タイムスタンプ',
                          '${receipt.createdAt.millisecondsSinceEpoch} ms',
                        ),
                        const Divider(),
                        _buildCopyableInfoRow(
                          context,
                          'タイムスタンプ (日時)',
                          '${receipt.createdAt.year}/${receipt.createdAt.month.toString().padLeft(2, '0')}/${receipt.createdAt.day.toString().padLeft(2, '0')} '
                          '${receipt.createdAt.hour.toString().padLeft(2, '0')}:${receipt.createdAt.minute.toString().padLeft(2, '0')}:'
                          '${receipt.createdAt.second.toString().padLeft(2, '0')}.${receipt.createdAt.millisecond.toString().padLeft(3, '0')}',
                        ),
                        if (receipt.pdfUrl != null) ...[
                          const Divider(),
                          _buildLinkInfoRow(
                            context,
                            'PDF URL',
                            receipt.pdfUrl!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: UIConstants.paddingLarge),

                // PDFボタン
                if (receipt.pdfUrl != null)
                  ElevatedButton.icon(
                    onPressed: () => _showPdfModal(context, receipt.pdfUrl!),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDFを表示'),
                  ),
              ],
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
            ],
          ),
        ),
      ),
    );
  }

  void _showPdfModal(BuildContext context, String pdfUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '領収書',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // 共有ボタン
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () async {
                          await Share.shareUri(Uri.parse(pdfUrl));
                        },
                      ),
                      // 外部ブラウザで開くボタン
                      IconButton(
                        icon: const Icon(Icons.open_in_browser),
                        onPressed: () async {
                          final uri = Uri.parse(pdfUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      // 閉じるボタン
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(),
              // PDFビューワー
              Expanded(
                child: SfPdfViewer.network(
                  pdfUrl,
                  onDocumentLoadFailed: (details) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('PDFの読み込みに失敗しました: ${details.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('コピーしました'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkInfoRow(BuildContext context, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UIConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
