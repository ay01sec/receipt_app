import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/store.dart';
import '../utils/constants.dart';

/// 店舗情報に関するビジネスロジックを管理するリポジトリ
class StoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ユーザーの店舗情報を取得
  Future<Store?> getStore(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return Store.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('店舗情報の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 店舗情報をIDで取得
  Future<Store?> getStoreById(String userId, String storeId) async {
    try {
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Store.fromFirestore(doc);
    } catch (e) {
      throw Exception('店舗情報の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 店舗情報を作成
  Future<Store> createStore({
    required String userId,
    required String storeName,
    required String storeAddress1,
    String storeAddress2 = '',
    required String phoneNumber,
    required String invoiceNumber,
    required String defaultMemo,
    String? stampImagePath,
  }) async {
    try {
      final now = Timestamp.now();
      String? stampImageUrl;

      // 印鑑画像をアップロード
      if (stampImagePath != null) {
        stampImageUrl = await _uploadStampImage(userId, stampImagePath);
      }

      // Firestoreに店舗情報を保存（サブコレクション構造）
      final docRef = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .add({
        'userId': userId,
        'storeName': storeName,
        'storeAddress1': storeAddress1,
        'storeAddress2': storeAddress2,
        'phoneNumber': phoneNumber,
        'stampImageUrl': stampImageUrl,
        'invoiceNumber': invoiceNumber,
        'defaultMemo': defaultMemo,
        'receiptNumberPrefix': 'R-',
        'lastReceiptNumber': 0,
        'fiscalYearStart': 1,
        'createdAt': now,
        'updatedAt': now,
      });

      final doc = await docRef.get();
      return Store.fromFirestore(doc);
    } catch (e) {
      throw Exception('店舗情報の作成に失敗しました: ${e.toString()}');
    }
  }

  /// 店舗情報を更新
  Future<Store> updateStore({
    required String userId,
    required String storeId,
    String? storeName,
    String? storeAddress1,
    String? storeAddress2,
    String? phoneNumber,
    String? invoiceNumber,
    String? defaultMemo,
    String? stampImagePath,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (storeName != null) updateData['storeName'] = storeName;
      if (storeAddress1 != null) updateData['storeAddress1'] = storeAddress1;
      if (storeAddress2 != null) updateData['storeAddress2'] = storeAddress2;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (invoiceNumber != null) updateData['invoiceNumber'] = invoiceNumber;
      if (defaultMemo != null) updateData['defaultMemo'] = defaultMemo;

      // 印鑑画像をアップロード
      if (stampImagePath != null) {
        final stampImageUrl = await _uploadStampImage(
          userId,
          stampImagePath,
        );
        updateData['stampImageUrl'] = stampImageUrl;
      }

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .update(updateData);

      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .get();

      return Store.fromFirestore(doc);
    } catch (e) {
      throw Exception('店舗情報の更新に失敗しました: ${e.toString()}');
    }
  }

  /// 領収書番号をインクリメント
  Future<void> incrementReceiptNumber(String userId, String storeId) async {
    try {
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .update({
        'lastReceiptNumber': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('領収書番号の更新に失敗しました: ${e.toString()}');
    }
  }

  /// 印鑑画像をCloud Storageにアップロード
  Future<String> _uploadStampImage(String userId, String filePath) async {
    try {
      final file = File(filePath);
      final storageRef = _storage.ref().child(
            StoragePaths.stampImagePath(userId),
          );

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('印鑑画像のアップロードに失敗しました: ${e.toString()}');
    }
  }

  /// 印鑑画像を削除
  Future<void> deleteStampImage(String userId) async {
    try {
      final storageRef = _storage.ref().child(
            StoragePaths.stampImagePath(userId),
          );
      await storageRef.delete();
    } catch (e) {
      // 画像が存在しない場合はエラーを無視
      if (!e.toString().contains('object-not-found')) {
        throw Exception('印鑑画像の削除に失敗しました: ${e.toString()}');
      }
    }
  }

  /// 店舗情報を削除
  Future<void> deleteStore(String userId, String storeId) async {
    try {
      // 印鑑画像を削除
      await deleteStampImage(userId);

      // Firestoreから店舗情報を削除
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userId)
          .collection(FirestoreCollections.stores)
          .doc(storeId)
          .delete();
    } catch (e) {
      throw Exception('店舗情報の削除に失敗しました: ${e.toString()}');
    }
  }
}
