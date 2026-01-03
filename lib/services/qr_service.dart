import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// QRコード生成サービス
class QrService {
  /// 領収書情報からQRコードデータを生成
  ///
  /// [receiptId] 領収書ID
  /// [receiptNumber] 領収書番号
  /// [issueDate] 発行日
  /// [totalAmount] 税込金額
  /// [storeName] 店舗名
  /// [verifyUrl] 検証用URL（オプション）
  static String generateQrData({
    required String receiptId,
    required String receiptNumber,
    required DateTime issueDate,
    required int totalAmount,
    required String storeName,
    String? verifyUrl,
  }) {
    final data = {
      'receiptId': receiptId,
      'receiptNumber': receiptNumber,
      'issueDate': issueDate.toIso8601String(),
      'timestamp': issueDate.millisecondsSinceEpoch, // Unix timestamp (milliseconds)
      'totalAmount': totalAmount,
      'storeName': storeName,
      if (verifyUrl != null) 'verifyUrl': verifyUrl,
    };

    return jsonEncode(data);
  }

  /// QRコードウィジェットを生成
  ///
  /// [data] QRコードにエンコードするデータ
  /// [size] QRコードのサイズ（デフォルト: 200.0）
  /// [backgroundColor] 背景色（デフォルト: 白）
  /// [foregroundColor] QRコードの色（デフォルト: 黒）
  static Widget generateQrWidget({
    required String data,
    double size = 200.0,
    Color backgroundColor = Colors.white,
    Color foregroundColor = Colors.black,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      errorCorrectionLevel: QrErrorCorrectLevel.H, // 高い訂正レベル
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(40, 40),
      ),
    );
  }

  /// 検証URLを生成
  ///
  /// [baseUrl] ベースURL（例: https://yourapp.com）
  /// [receiptId] 領収書ID
  static String generateVerifyUrl(String baseUrl, String receiptId) {
    return '$baseUrl/verify/$receiptId';
  }

  /// QRコードデータをパース
  static Map<String, dynamic>? parseQrData(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
