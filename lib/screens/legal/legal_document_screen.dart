import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

/// 法的文書表示画面（Markdown）
class LegalDocumentScreen extends StatefulWidget {
  /// ドキュメントのパス（assets/ からの相対パス）
  final String documentPath;

  /// 画面タイトル
  final String title;

  const LegalDocumentScreen({
    super.key,
    required this.documentPath,
    required this.title,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  String _markdownContent = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  /// ドキュメントを読み込み
  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final content = await rootBundle.loadString(widget.documentPath);
      setState(() {
        _markdownContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'ドキュメントの読み込みに失敗しました: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// URLを開く
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URLを開けませんでした: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMarkdownView(),
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
              onPressed: _loadDocument,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }

  /// Markdown表示
  Widget _buildMarkdownView() {
    return Markdown(
      data: _markdownContent,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          // # で始まるリンク（アンカー）の場合は何もしない
          if (href.startsWith('#')) {
            return;
          }
          _launchUrl(href);
        }
      },
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        p: const TextStyle(
          fontSize: 14,
          height: 1.6,
        ),
        listBullet: const TextStyle(
          fontSize: 14,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey.shade200,
          fontFamily: 'monospace',
        ),
        blockquote: TextStyle(
          color: Colors.grey.shade700,
          fontStyle: FontStyle.italic,
        ),
        a: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
      padding: const EdgeInsets.all(UIConstants.paddingLarge),
    );
  }
}
