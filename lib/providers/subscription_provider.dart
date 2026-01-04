import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/revenue_cat_service.dart';
import '../utils/constants.dart';

/// サブスクリプション状態を取得するFutureProvider
final subscriptionStatusProvider =
    FutureProvider<SubscriptionStatus>((ref) async {
  return await RevenueCatService.getSubscriptionStatus();
});

/// プレミアム会員かどうかをチェックするFutureProvider
final isPremiumProvider = FutureProvider<bool>((ref) async {
  return await RevenueCatService.isPremium();
});

/// サブスクリプションコントローラー
class SubscriptionController extends StateNotifier<AsyncValue<CustomerInfo?>> {
  SubscriptionController() : super(const AsyncValue.data(null)) {
    _loadCustomerInfo();
  }

  /// ユーザー情報を読み込み
  Future<void> _loadCustomerInfo() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await RevenueCatService.getCustomerInfo();
    });
  }

  /// サブスクリプション商品一覧を取得
  Future<Offerings?> getOfferings() async {
    try {
      return await RevenueCatService.getOfferings();
    } catch (e) {
      return null;
    }
  }

  /// サブスクリプションを購入
  Future<bool> purchase(Package package) async {
    state = const AsyncValue.loading();
    try {
      print('🔵 購入処理開始: ${package.identifier}');
      final customerInfo = await RevenueCatService.purchase(package);

      print('🟢 購入成功 - CustomerInfo を取得');
      print('🔵 Firestore UserData を更新中...');

      // 購入成功後、Firestoreを即座に更新
      await _updateFirestoreSubscription(customerInfo);

      print('🟢 Firestore UserData 更新完了');
      state = AsyncValue.data(customerInfo);
      return true;
    } catch (e, stack) {
      print('🔴 購入エラー: $e');
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// Firestoreのサブスクリプション情報を更新
  Future<void> _updateFirestoreSubscription(CustomerInfo customerInfo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('⚠️ ユーザーが見つかりません');
        return;
      }

      final premiumEntitlement = customerInfo.entitlements.all['premium'];

      if (premiumEntitlement != null && premiumEntitlement.isActive) {
        // サブスクリプションが有効な場合
        final productId = premiumEntitlement.productIdentifier;
        String? plan;

        // Product ID からプラン名を判定
        if (productId.contains('monthly')) {
          plan = 'monthly';
        } else if (productId.contains('premium') || productId.contains('yearly')) {
          plan = 'yearly';
        }

        // Firestoreを更新
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .update({
          'subscriptionPlan': plan,
          'subscriptionStatus': 'active',
          'subscriptionStartDate': premiumEntitlement.latestPurchaseDate != null
              ? Timestamp.fromDate(DateTime.parse(premiumEntitlement.latestPurchaseDate!))
              : FieldValue.serverTimestamp(),
          'subscriptionEndDate': premiumEntitlement.expirationDate != null
              ? Timestamp.fromDate(DateTime.parse(premiumEntitlement.expirationDate!))
              : null,
          'autoRenew': premiumEntitlement.willRenew,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('🟢 Firestore更新成功: plan=$plan, status=active');
      } else {
        // サブスクリプションが無効な場合
        await FirebaseFirestore.instance
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .update({
          'subscriptionStatus': 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('🟢 Firestore更新成功: status=inactive');
      }
    } catch (e, stack) {
      print('🔴 Firestore更新エラー: $e');
      print('🔴 StackTrace: $stack');
      // Firestoreの更新に失敗してもエラーにはしない（購入自体は成功している）
    }
  }

  /// 購入をリストア
  Future<bool> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      print('🔵 購入情報のリストア開始');
      final customerInfo = await RevenueCatService.restorePurchases();

      print('🟢 リストア成功 - CustomerInfo を取得');
      print('🔵 Firestore UserData を更新中...');

      // リストア成功後、Firestoreを即座に更新
      await _updateFirestoreSubscription(customerInfo);

      print('🟢 Firestore UserData 更新完了');
      state = AsyncValue.data(customerInfo);
      return true;
    } catch (e, stack) {
      print('🔴 リストアエラー: $e');
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// ユーザー情報をリフレッシュ
  Future<void> refresh() async {
    await _loadCustomerInfo();
  }

  /// プレミアム会員かどうかをチェック
  bool get isPremium {
    final customerInfo = state.value;
    if (customerInfo == null) return false;

    final premiumEntitlement = customerInfo.entitlements.all['premium'];
    return premiumEntitlement != null && premiumEntitlement.isActive;
  }
}

/// SubscriptionControllerのプロバイダー
final subscriptionControllerProvider =
    StateNotifierProvider<SubscriptionController, AsyncValue<CustomerInfo?>>(
  (ref) => SubscriptionController(),
);
