import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/revenue_cat_service.dart';

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
      final customerInfo = await RevenueCatService.purchase(package);
      state = AsyncValue.data(customerInfo);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  /// 購入をリストア
  Future<bool> restorePurchases() async {
    state = const AsyncValue.loading();
    try {
      final customerInfo = await RevenueCatService.restorePurchases();
      state = AsyncValue.data(customerInfo);
      return true;
    } catch (e, stack) {
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
