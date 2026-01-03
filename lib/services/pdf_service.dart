import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../utils/validators.dart';

/// PDF生成サービス
class PdfService {
  /// 日本語フォントを読み込み
  static Future<pw.Font> _loadFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  /// 太字日本語フォントを読み込み
  static Future<pw.Font> _loadBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/NotoSansJP-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  /// 領収書PDFを生成
  ///
  /// [receiptNumber] 領収書番号
  /// [issueDate] 発行日
  /// [recipientName] 宛名
  /// [memo] 但し書き
  /// [totalAmount] 税込金額
  /// [subtotalAmount] 税抜金額
  /// [taxAmount] 消費税額
  /// [taxRate] 税率
  /// [storeName] 店舗名
  /// [storeAddress] 店舗住所
  /// [phoneNumber] 電話番号
  /// [invoiceNumber] インボイス番号
  /// [stampImageBytes] 印鑑画像データ（オプション）
  /// [qrCodeData] QRコードデータ
  static Future<Uint8List> generateReceiptPdf({
    required String receiptNumber,
    required DateTime issueDate,
    required String recipientName,
    required String memo,
    required int totalAmount,
    required int subtotalAmount,
    required int taxAmount,
    required double taxRate,
    required String storeName,
    required String storeAddress,
    required String phoneNumber,
    String? invoiceNumber,
    Uint8List? stampImageBytes,
    required String qrCodeData,
  }) async {
    final pdf = pw.Document();
    final font = await _loadFont();
    final boldFont = await _loadBoldFont();

    // 印鑑画像をメモリイメージに変換
    pw.MemoryImage? stampImage;
    if (stampImageBytes != null) {
      stampImage = pw.MemoryImage(stampImageBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ヘッダー部分（タイトルと発行日）
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(width: 150), // 左側の余白
                // 中央：領収書タイトル
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      '領収書',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 右側：発行日
                pw.Container(
                  width: 150,
                  alignment: pw.Alignment.topRight,
                  child: pw.Text(
                    '発行日：${Formatters.formatDate(issueDate)}',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // 宛名
            pw.Text(
              '$recipientName',
              style: pw.TextStyle(font: font, fontSize: 16),
            ),
            pw.SizedBox(height: 30),

            // 金額ボックス（大きく中央に）
            pw.Center(
              child: pw.Container(
                width: 400,
                padding: const pw.EdgeInsets.symmetric(vertical: 25, horizontal: 20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 3),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '¥${Formatters.formatAmount(totalAmount)}-',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 48,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // 但し書き
            pw.Center(
              child: pw.Text(
                '但し、$memo として',
                style: pw.TextStyle(font: font, fontSize: 14),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                '上記、正に領収いたしました',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ),

            pw.Spacer(),

            // 下部：印紙枠（左）と店舗情報・印鑑（右）
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // 左側：印紙枠
                pw.Container(
                  width: 180,
                  height: 120,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Center(
                        child: pw.Text(
                          '印紙',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '内訳',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '税抜金額',
                            style: pw.TextStyle(font: font, fontSize: 9),
                          ),
                          pw.Text(
                            '¥${Formatters.formatAmount(subtotalAmount)}',
                            style: pw.TextStyle(font: font, fontSize: 9),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '消費税等',
                            style: pw.TextStyle(font: font, fontSize: 9),
                          ),
                          pw.Text(
                            '¥${Formatters.formatAmount(taxAmount)}',
                            style: pw.TextStyle(font: font, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 右側：店舗情報と印鑑
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // 店舗情報
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '金額　$storeName',
                          style: pw.TextStyle(font: font, fontSize: 10),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          storeAddress,
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'TEL: $phoneNumber',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                        if (invoiceNumber != null) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'インボイス番号: $invoiceNumber',
                            style: pw.TextStyle(font: font, fontSize: 8),
                          ),
                        ],
                      ],
                    ),
                    pw.SizedBox(width: 15),
                    // 印鑑
                    if (stampImage != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        child: pw.Image(stampImage),
                      ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 10),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
