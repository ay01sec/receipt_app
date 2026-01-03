import 'package:cloud_firestore/cloud_firestore.dart';

/// 店舗情報データモデル
class Store {
  final String id; // 店舗ID（FirestoreのドキュメントID）
  final String userId; // ユーザーID（店舗所有者）
  final String storeName; // 店舗名
  final String storeAddress1; // 店舗住所1
  final String storeAddress2; // 店舗住所2（オプション）
  final String phoneNumber; // 電話番号
  final String? stampImageUrl; // 印鑑画像URL（Cloud Storage）
  final String invoiceNumber; // インボイス番号
  final String defaultMemo; // 但し書きのデフォルト値
  final String receiptNumberPrefix; // 領収書番号の接頭辞（例: R-2026-）
  final int lastReceiptNumber; // 最後に発行した連番
  final int fiscalYearStart; // 会計年度開始月（1-12）
  final DateTime createdAt; // 作成日時
  final DateTime updatedAt; // 更新日時

  Store({
    required this.id,
    required this.userId,
    required this.storeName,
    required this.storeAddress1,
    this.storeAddress2 = '',
    required this.phoneNumber,
    this.stampImageUrl,
    required this.invoiceNumber,
    required this.defaultMemo,
    this.receiptNumberPrefix = 'R-',
    this.lastReceiptNumber = 0,
    this.fiscalYearStart = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestoreドキュメントから店舗オブジェクトを作成
  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      userId: data['userId'] ?? '',
      storeName: data['storeName'] ?? '',
      storeAddress1: data['storeAddress1'] ?? '',
      storeAddress2: data['storeAddress2'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      stampImageUrl: data['stampImageUrl'],
      invoiceNumber: data['invoiceNumber'] ?? '',
      defaultMemo: data['defaultMemo'] ?? '',
      receiptNumberPrefix: data['receiptNumberPrefix'] ?? 'R-',
      lastReceiptNumber: data['lastReceiptNumber'] ?? 0,
      fiscalYearStart: data['fiscalYearStart'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'storeName': storeName,
      'storeAddress1': storeAddress1,
      'storeAddress2': storeAddress2,
      'phoneNumber': phoneNumber,
      'stampImageUrl': stampImageUrl,
      'invoiceNumber': invoiceNumber,
      'defaultMemo': defaultMemo,
      'receiptNumberPrefix': receiptNumberPrefix,
      'lastReceiptNumber': lastReceiptNumber,
      'fiscalYearStart': fiscalYearStart,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// コピーメソッド
  Store copyWith({
    String? id,
    String? userId,
    String? storeName,
    String? storeAddress1,
    String? storeAddress2,
    String? phoneNumber,
    String? stampImageUrl,
    String? invoiceNumber,
    String? defaultMemo,
    String? receiptNumberPrefix,
    int? lastReceiptNumber,
    int? fiscalYearStart,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      storeName: storeName ?? this.storeName,
      storeAddress1: storeAddress1 ?? this.storeAddress1,
      storeAddress2: storeAddress2 ?? this.storeAddress2,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      stampImageUrl: stampImageUrl ?? this.stampImageUrl,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      defaultMemo: defaultMemo ?? this.defaultMemo,
      receiptNumberPrefix: receiptNumberPrefix ?? this.receiptNumberPrefix,
      lastReceiptNumber: lastReceiptNumber ?? this.lastReceiptNumber,
      fiscalYearStart: fiscalYearStart ?? this.fiscalYearStart,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 完全な住所を取得
  String get fullAddress {
    if (storeAddress2.isEmpty) {
      return storeAddress1;
    }
    return '$storeAddress1 $storeAddress2';
  }

  /// 次の領収書番号を生成
  String generateNextReceiptNumber() {
    final now = DateTime.now();
    final year = now.year;
    final nextNumber = lastReceiptNumber + 1;
    return '$receiptNumberPrefix$year-${nextNumber.toString().padLeft(5, '0')}';
  }
}
