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
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ヘッダー（領収書タイトル）
            pw.Center(
              child: pw.Text(
                '領収書',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 30),

            // 領収書番号と発行日
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '領収書No: $receiptNumber',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
                pw.Text(
                  '発行日: ${Formatters.formatDate(issueDate)}',
                  style: pw.TextStyle(font: font, fontSize: 10),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // 宛名
            pw.Text(
              recipientName,
              style: pw.TextStyle(font: font, fontSize: 16),
            ),
            pw.SizedBox(height: 30),

            // 金額ボックス
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 2),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    '金額',
                    style: pw.TextStyle(font: font, fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '¥${Formatters.formatAmount(totalAmount)}-',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 36,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // 但し書き
            pw.Text(
              '但し、$memo',
              style: pw.TextStyle(font: font, fontSize: 14),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '上記、正に領収いたしました',
              style: pw.TextStyle(font: font, fontSize: 12),
            ),
            pw.SizedBox(height: 30),

            // 内訳
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1, color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '内訳',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '税抜金額',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                      pw.Text(
                        '¥${Formatters.formatAmount(subtotalAmount)}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '消費税（${taxRate.toStringAsFixed(0)}%）',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                      pw.Text(
                        '¥${Formatters.formatAmount(taxAmount)}',
                        style: pw.TextStyle(font: font, fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '税込金額',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '¥${Formatters.formatAmount(totalAmount)}',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // 店舗情報と印鑑・QRコード
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 店舗情報
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      storeName,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      storeAddress,
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'TEL: $phoneNumber',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    if (invoiceNumber != null) ...[
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'インボイス番号: $invoiceNumber',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ],
                  ],
                ),

                // 印鑑とQRコード
                pw.Row(
                  children: [
                    // 印鑑画像
                    if (stampImage != null)
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.Image(stampImage),
                      ),
                    pw.SizedBox(width: 10),
                    // QRコード
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrCodeData,
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}
