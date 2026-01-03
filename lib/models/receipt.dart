import 'package:cloud_firestore/cloud_firestore.dart';

/// 領収書データモデル
class Receipt {
  final String id; // 領収書ID（FirestoreのドキュメントID）
  final String receiptNumber; // 領収書番号（例: R-2026-00001）
  final String status; // ステータス（draft, issued, deleted）
  final DateTime issueDate; // 発行日
  final String issueDateString; // 発行日文字列（例: 2026年01月03日）
  final String recipientName; // 宛名（「様」付き）
  final String memo; // 但し書き
  final int totalAmount; // 税込合計金額
  final int subtotalAmount; // 税抜金額
  final int taxAmount; // 消費税額
  final double taxRate; // 税率（例: 10.0）
  final String qrCodeData; // QRコードデータ
  final String? pdfUrl; // PDF URL（Cloud Storage）
  final String? pdfStoragePath; // Storage内のパス
  final DateTime createdAt; // 作成日時
  final DateTime updatedAt; // 更新日時
  final DateTime? deletedAt; // 削除日時（論理削除用）

  Receipt({
    required this.id,
    required this.receiptNumber,
    required this.status,
    required this.issueDate,
    required this.issueDateString,
    required this.recipientName,
    required this.memo,
    required this.totalAmount,
    required this.subtotalAmount,
    required this.taxAmount,
    required this.taxRate,
    required this.qrCodeData,
    this.pdfUrl,
    this.pdfStoragePath,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Firestoreドキュメントから領収書オブジェクトを作成
  factory Receipt.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Receipt(
      id: doc.id,
      receiptNumber: data['receiptNumber'] ?? '',
      status: data['status'] ?? 'draft',
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      issueDateString: data['issueDateString'] ?? '',
      recipientName: data['recipientName'] ?? '',
      memo: data['memo'] ?? '',
      totalAmount: data['totalAmount'] ?? 0,
      subtotalAmount: data['subtotalAmount'] ?? 0,
      taxAmount: data['taxAmount'] ?? 0,
      taxRate: (data['taxRate'] ?? 10.0).toDouble(),
      qrCodeData: data['qrCodeData'] ?? '',
      pdfUrl: data['pdfUrl'],
      pdfStoragePath: data['pdfStoragePath'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      deletedAt: data['deletedAt'] != null
          ? (data['deletedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'receiptNumber': receiptNumber,
      'status': status,
      'issueDate': Timestamp.fromDate(issueDate),
      'issueDateString': issueDateString,
      'recipientName': recipientName,
      'memo': memo,
      'totalAmount': totalAmount,
      'subtotalAmount': subtotalAmount,
      'taxAmount': taxAmount,
      'taxRate': taxRate,
      'qrCodeData': qrCodeData,
      'pdfUrl': pdfUrl,
      'pdfStoragePath': pdfStoragePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (deletedAt != null) 'deletedAt': Timestamp.fromDate(deletedAt!),
    };
  }

  /// コピーメソッド（一部のフィールドを更新する場合に使用）
  Receipt copyWith({
    String? id,
    String? receiptNumber,
    String? status,
    DateTime? issueDate,
    String? issueDateString,
    String? recipientName,
    String? memo,
    int? totalAmount,
    int? subtotalAmount,
    int? taxAmount,
    double? taxRate,
    String? qrCodeData,
    String? pdfUrl,
    String? pdfStoragePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      status: status ?? this.status,
      issueDate: issueDate ?? this.issueDate,
      issueDateString: issueDateString ?? this.issueDateString,
      recipientName: recipientName ?? this.recipientName,
      memo: memo ?? this.memo,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotalAmount: subtotalAmount ?? this.subtotalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      taxRate: taxRate ?? this.taxRate,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfStoragePath: pdfStoragePath ?? this.pdfStoragePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
