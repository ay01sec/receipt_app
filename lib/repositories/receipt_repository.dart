import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/receipt.dart';
import '../models/store.dart';
import '../utils/constants.dart';
import '../services/pdf_service.dart';
import '../services/qr_service.dart';
import '../utils/validators.dart';

/// 領収書に関するビジネスロジックを管理するリポジトリ
class ReceiptRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 領収書を作成
  Future<Receipt> createReceipt({
    required Store store,
    required String recipientName,
    required String memo,
    required int totalAmount,
    required double taxRate,
    Uint8List? stampImageBytes,
  }) async {
    try {
      print('🔵 ReceiptRepository: 領収書作成開始 - userId: ${store.userId}, storeId: ${store.id}');

      // 税抜金額と消費税を計算
      final subtotalAmount = TaxRates.calculateSubtotal(totalAmount, taxRate);
      final taxAmount = TaxRates.calculateTax(subtotalAmount, taxRate);

      print('🔵 ReceiptRepository: 金額計算完了 - total: $totalAmount, tax: $taxAmount');

      // 領収書番号を生成
      final receiptNumber = store.generateNextReceiptNumber();

      // 発行日
      final issueDate = DateTime.now();
      final issueDateString = Formatters.formatDate(issueDate);

      // QRコードデータを生成
      final qrCodeData = QrService.generateQrData(
        receiptId: '', // 仮のID（後で更新）
        receiptNumber: receiptNumber,
        issueDate: issueDate,
        totalAmount: totalAmount,
        storeName: store.storeName,
      );

      // PDFを生成
      print('🔵 ReceiptRepository: PDF生成開始');
      final pdfBytes = await PdfService.generateReceiptPdf(
        receiptNumber: receiptNumber,
        issueDate: issueDate,
        recipientName: recipientName,
        memo: memo,
        totalAmount: totalAmount,
        subtotalAmount: subtotalAmount,
        taxAmount: taxAmount,
        taxRate: taxRate,
        storeName: store.storeName,
        storeAddress: store.fullAddress,
        phoneNumber: store.phoneNumber,
        invoiceNumber: store.invoiceNumber.isNotEmpty ? store.invoiceNumber : null,
        stampImageBytes: stampImageBytes,
        qrCodeData: qrCodeData,
      );
      print('🟢 ReceiptRepository: PDF生成完了 - ${pdfBytes.length} bytes');

      // Firestoreに領収書情報を保存（サブコレクション構造）
      final now = Timestamp.now();
      print('🔵 ReceiptRepository: Firestore保存開始');
      final docRef = await _firestore
          .collection(FirestoreCollections.users)
          .doc(store.userId)
          .collection(FirestoreCollections.stores)
          .doc(store.id)
          .collection(FirestoreCollections.receipts)
          .add({
        'receiptNumber': receiptNumber,
        'status': ReceiptStatus.issued,
        'issueDate': Timestamp.fromDate(issueDate),
        'issueDateString': issueDateString,
        'recipientName': recipientName,
        'memo': memo,
        'totalAmount': totalAmount,
        'subtotalAmount': subtotalAmount,
        'taxAmount': taxAmount,
        'taxRate': taxRate,
        'qrCodeData': qrCodeData,
        'pdfUrl': null,
        'pdfStoragePath': null,
        'createdAt': now,
        'updatedAt': now,
      });

      print('🟢 ReceiptRepository: Firestore保存完了 - receiptId: ${docRef.id}');

      // PDFをCloud Storageにアップロード
      final pdfStoragePath = StoragePaths.receiptPdfPath(store.userId, store.id, docRef.id);
      print('🔵 ReceiptRepository: Storageアップロード開始 - path: $pdfStoragePath');

      final storageRef = _storage.ref().child(pdfStoragePath);
      print('🔵 ReceiptRepository: StorageRef取得完了');

      await storageRef.putData(pdfBytes);
      print('🟢 ReceiptRepository: PDF putData 完了');

      final pdfUrl = await storageRef.getDownloadURL();
      print('🟢 ReceiptRepository: DownloadURL取得完了 - url: $pdfUrl');

      // PDFのURLを更新
      print('🔵 ReceiptRepository: Firestore PDF URL更新開始');
      await docRef.update({
        'pdfUrl': pdfUrl,
        'pdfStoragePath': pdfStoragePath,
        'updatedAt': Timestamp.now(),
      });
      print('🟢 ReceiptRepository: Firestore PDF URL更新完了');

      // 領収書番号をインクリメント（StoreRepositoryを経由せず直接更新）
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(store.userId)
          .collection(FirestoreCollections.stores)
          .doc(store.id)
          .update({
        'lastReceiptNumber': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      // 作成した領収書を取得
      final doc = await docRef.get();
      final receipt = Receipt.fromFirestore(doc);
      print('🟢 ReceiptRepository: 領収書作成完了 - receiptNumber: ${receipt.receiptNumber}, pdfUrl: ${receipt.pdfUrl}');
      return receipt;
    } catch (e, stackTrace) {
      print('🔴 ReceiptRepository: エラー発生 - $e');
      print('🔴 StackTrace: $stackTrace');
      throw Exception('領収書の作成に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書を取得
  Future<Receipt?> getReceipt(String userId, String storeId, String receiptId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .collection(FirestoreCollections.receipts)
          .doc(receiptId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Receipt.fromFirestore(doc);
    } catch (e) {
      throw Exception('領収書の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書一覧を取得（最新順）
  Future<List<Receipt>> getReceipts({
    required String userId,
    required String storeId,
    int limit = 20,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .collection(FirestoreCollections.receipts)
          .where('status', isEqualTo: ReceiptStatus.issued)
          .orderBy('issueDate', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Receipt.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('領収書一覧の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書を検索
  Future<List<Receipt>> searchReceipts({
    required String userId,
    required String storeId,
    DateTime? startDate,
    DateTime? endDate,
    String? recipientName,
    int? minAmount,
    int? maxAmount,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .collection(FirestoreCollections.receipts)
          .where('status', isEqualTo: ReceiptStatus.issued);

      // 日付範囲で検索
      if (startDate != null) {
        query = query.where(
          'issueDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        // 終了日の23:59:59まで含める
        final endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        query = query.where(
          'issueDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDateTime),
        );
      }

      // 宛名で検索
      if (recipientName != null && recipientName.isNotEmpty) {
        query = query.where('recipientName', isEqualTo: recipientName);
      }

      // 金額範囲で検索
      if (minAmount != null) {
        query = query.where('totalAmount', isGreaterThanOrEqualTo: minAmount);
      }
      if (maxAmount != null) {
        query = query.where('totalAmount', isLessThanOrEqualTo: maxAmount);
      }

      query = query.orderBy('issueDate', descending: true).limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Receipt.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('領収書の検索に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書を削除（論理削除）
  Future<void> deleteReceipt(String userId, String storeId, String receiptId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .collection(FirestoreCollections.receipts)
          .doc(receiptId)
          .update({
        'status': ReceiptStatus.deleted,
        'deletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('領収書の削除に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書を完全削除（物理削除）
  Future<void> permanentlyDeleteReceipt(
    String userId,
    String storeId,
    String receiptId,
  ) async {
    try {
      // PDFを削除
      final receipt = await getReceipt(userId, storeId, receiptId);
      if (receipt?.pdfStoragePath != null) {
        try {
          await _storage.ref().child(receipt!.pdfStoragePath!).delete();
        } catch (e) {
          // PDFが存在しない場合はエラーを無視
        }
      }

      // Firestoreから削除
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .collection(FirestoreCollections.receipts)
          .doc(receiptId)
          .delete();
    } catch (e) {
      throw Exception('領収書の完全削除に失敗しました: ${e.toString()}');
    }
  }
}
