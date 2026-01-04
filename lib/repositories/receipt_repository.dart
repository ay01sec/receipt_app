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

      // 発行日
      final issueDate = DateTime.now();
      final issueDateString = Formatters.formatDate(issueDate);

      // Firestoreから最新のlastReceiptNumberを取得して番号を生成
      print('🔵 ReceiptRepository: 最新の領収書番号取得中');
      final storeDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(store.userId)
          .collection(FirestoreCollections.stores)
          .doc(store.id)
          .get();

      final currentLastNumber = storeDoc.data()?['lastReceiptNumber'] as int? ?? 0;
      final nextNumber = currentLastNumber + 1;
      final receiptNumber = 'R-${issueDate.year}-${nextNumber.toString().padLeft(5, '0')}';
      print('🟢 ReceiptRepository: 領収書番号生成 - $receiptNumber (last: $currentLastNumber, next: $nextNumber)');

      // 先にFirestoreドキュメントを作成してIDを取得
      final now = Timestamp.now();
      print('🔵 ReceiptRepository: Firestore仮保存開始');
      final docRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(store.userId)
          .collection(FirestoreCollections.stores)
          .doc(store.id)
          .collection(FirestoreCollections.receipts)
          .doc(); // 先にIDを生成

      final receiptId = docRef.id;
      print('🟢 ReceiptRepository: ReceiptID生成完了 - $receiptId');

      // 第1段階: QRコードなしでPDFを生成（仮）
      print('🔵 ReceiptRepository: 第1段階PDF生成開始（QRコードなし）');
      final tempPdfBytes = await PdfService.generateReceiptPdf(
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
        qrCodeData: null, // 第1段階ではQRコードなし
      );
      print('🟢 ReceiptRepository: 第1段階PDF生成完了 - ${tempPdfBytes.length} bytes');

      // Firestoreにデータを保存（QRコードはまだ未設定）
      print('🔵 ReceiptRepository: Firestore保存開始');
      await docRef.set({
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
        'qrCodeData': '', // 第1段階では空
        'pdfUrl': null,
        'pdfStoragePath': null,
        'createdAt': now,
        'updatedAt': now,
      });

      print('🟢 ReceiptRepository: Firestore保存完了 - receiptId: ${docRef.id}');

      // 第1段階PDFをCloud Storageにアップロード
      final pdfStoragePath = StoragePaths.receiptPdfPath(store.userId, store.id, docRef.id);
      print('🔵 ReceiptRepository: 第1段階Storageアップロード開始 - path: $pdfStoragePath');

      final storageRef = _storage.ref().child(pdfStoragePath);
      print('🔵 ReceiptRepository: StorageRef取得完了');

      await storageRef.putData(tempPdfBytes);
      print('🟢 ReceiptRepository: 第1段階PDF putData 完了');

      final pdfUrl = await storageRef.getDownloadURL();
      print('🟢 ReceiptRepository: DownloadURL取得完了 - url: $pdfUrl');

      // 第2段階: PDF URLを使ってQRコード生成
      print('🔵 ReceiptRepository: QRコード生成開始（PDF URL使用）');
      final qrCodeData = QrService.generateQrDataFromUrl(pdfUrl: pdfUrl);
      print('🟢 ReceiptRepository: QRコード生成完了 - $qrCodeData');

      // 第2段階: QRコード付きPDFを再生成
      print('🔵 ReceiptRepository: 第2段階PDF生成開始（QRコード付き）');
      final finalPdfBytes = await PdfService.generateReceiptPdf(
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
      print('🟢 ReceiptRepository: 第2段階PDF生成完了 - ${finalPdfBytes.length} bytes');

      // 第2段階PDFをStorageに上書きアップロード
      print('🔵 ReceiptRepository: 第2段階Storageアップロード開始（上書き）');
      await storageRef.putData(finalPdfBytes);
      print('🟢 ReceiptRepository: 第2段階PDF putData 完了');

      // FirestoreにPDF URLとQRコードデータを更新
      print('🔵 ReceiptRepository: Firestore PDF URL & QRコード更新開始');
      await docRef.update({
        'pdfUrl': pdfUrl,
        'pdfStoragePath': pdfStoragePath,
        'qrCodeData': qrCodeData,
        'updatedAt': Timestamp.now(),
      });
      print('🟢 ReceiptRepository: Firestore更新完了');

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

      // メール送信が有効な場合、メール送信キューに追加
      if (store.emailNotificationEnabled) {
        print('🔵 ReceiptRepository: メール送信キューに追加中');
        await _addToEmailQueue(
          userId: store.userId,
          receipt: receipt,
          store: store,
        );
        print('🟢 ReceiptRepository: メール送信キュー追加完了');
      }

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

      // 日付範囲で検索（Firestore側で実行）
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

      // 宛名・金額フィルタはクライアント側で実行（インデックス不要）
      query = query.orderBy('issueDate', descending: true).limit(limit * 2); // 多めに取得

      final querySnapshot = await query.get();
      var receipts = querySnapshot.docs
          .map((doc) => Receipt.fromFirestore(doc))
          .toList();

      // クライアント側で宛名フィルタ（部分一致検索）
      if (recipientName != null && recipientName.isNotEmpty) {
        receipts = receipts.where((receipt) {
          return receipt.recipientName.contains(recipientName);
        }).toList();
      }

      // クライアント側で金額範囲フィルタ
      if (minAmount != null) {
        receipts = receipts.where((receipt) {
          return receipt.totalAmount >= minAmount;
        }).toList();
      }
      if (maxAmount != null) {
        receipts = receipts.where((receipt) {
          return receipt.totalAmount <= maxAmount;
        }).toList();
      }

      // 最終的なlimit適用
      return receipts.take(limit).toList();
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

  /// メール送信キューに追加
  Future<void> _addToEmailQueue({
    required String userId,
    required Receipt receipt,
    required Store store,
  }) async {
    try {
      // ユーザーのメールアドレスを取得（Firebaseの認証情報から）
      // ※実装時にはFirebaseAuthから取得する必要があります
      final userDoc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .get();

      final userEmail = userDoc.data()?['email'] as String?;
      if (userEmail == null) {
        print('🟡 ReceiptRepository: ユーザーのメールアドレスが見つかりません');
        return;
      }

      // メール送信キューにドキュメントを追加
      await _firestore.collection('emailQueue').add({
        'to': userEmail,
        'template': {
          'name': 'receiptCreated',
          'data': {
            'receiptNumber': receipt.receiptNumber,
            'recipientName': receipt.recipientName,
            'totalAmount': Formatters.formatAmount(receipt.totalAmount),
            'issueDateString': receipt.issueDateString,
            'storeName': store.storeName,
          },
        },
        'message': {
          'subject': '領収書が作成されました - ${receipt.receiptNumber}',
          'html': '''
            <h2>領収書が作成されました</h2>
            <p>以下の領収書が作成されました。</p>
            <h3>領収書情報</h3>
            <ul>
              <li><strong>領収書No:</strong> ${receipt.receiptNumber}</li>
              <li><strong>発行日:</strong> ${receipt.issueDateString}</li>
              <li><strong>宛名:</strong> ${receipt.recipientName}</li>
              <li><strong>但し書き:</strong> ${receipt.memo}</li>
              <li><strong>税込金額:</strong> ¥${Formatters.formatAmount(receipt.totalAmount)}</li>
              <li><strong>税抜金額:</strong> ¥${Formatters.formatAmount(receipt.subtotalAmount)}</li>
              <li><strong>消費税:</strong> ¥${Formatters.formatAmount(receipt.taxAmount)}</li>
              <li><strong>タイムスタンプ:</strong> ${receipt.createdAt.millisecondsSinceEpoch} ms</li>
            </ul>
            <h3>店舗情報</h3>
            <ul>
              <li><strong>店舗名:</strong> ${store.storeName}</li>
              <li><strong>住所:</strong> ${store.fullAddress}</li>
              <li><strong>電話番号:</strong> ${store.phoneNumber}</li>
            </ul>
            ${receipt.pdfUrl != null ? '<p><a href="${receipt.pdfUrl}">領収書PDFをダウンロード</a></p>' : ''}
          ''',
        },
        'attachments': receipt.pdfUrl != null
            ? [
                {
                  'filename': '${receipt.receiptNumber}.pdf',
                  'path': receipt.pdfUrl,
                }
              ]
            : [],
        'status': 'pending',
        'userId': userId,
        'receiptId': receipt.id,
        'createdAt': Timestamp.now(),
      });

      print('🟢 ReceiptRepository: メール送信キュー追加成功 - to: $userEmail');
    } catch (e) {
      print('🔴 ReceiptRepository: メール送信キュー追加エラー - $e');
      // メール送信エラーは無視して処理を続行
    }
  }
}
