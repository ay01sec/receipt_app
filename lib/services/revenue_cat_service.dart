import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCatサービス（サブスクリプション管理）
class RevenueCatService {
  static bool _isInitialized = false;

  /// RevenueCatを初期化
  ///
  /// [apiKey] RevenueCatのPublic API Key
  /// [userId] ユーザーID（オプション）
  static Future<void> initialize({
    required String apiKey,
    String? userId,
  }) async {
    if (_isInitialized) return;

    try {
      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = userId,
      );
      _isInitialized = true;
    } catch (e) {
      throw Exception('RevenueCatの初期化に失敗しました: ${e.toString()}');
    }
  }

  /// サブスクリプション商品一覧を取得
  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      throw Exception('サブスクリプション商品の取得に失敗しました: ${e.toString()}');
    }
  }

  /// 月額プランを取得
  static Future<Package?> getMonthlyPackage() async {
    final offerings = await getOfferings();
    return offerings?.current?.monthly;
  }

  /// 年額プランを取得
  static Future<Package?> getYearlyPackage() async {
    final offerings = await getOfferings();
    return offerings?.current?.annual;
  }

  /// サブスクリプションを購入
  ///
  /// [package] 購入するパッケージ
  static Future<CustomerInfo> purchase(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams(package: package),
      );
      return purchaseResult.customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw Exception('購入がキャンセルされました');
      } else if (errorCode == PurchasesErrorCode.purchaseNotAllowedError) {
        throw Exception('購入が許可されていません');
      } else {
        throw Exception('購入に失敗しました: ${e.message}');
      }
    } catch (e) {
      throw Exception('購入に失敗しました: ${e.toString()}');
    }
  }

  /// 購入をリストア
  static Future<CustomerInfo> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      throw Exception('購入のリストアに失敗しました: ${e.toString()}');
    }
  }

  /// 現在のユーザー情報を取得
  static Future<CustomerInfo> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      throw Exception('ユーザー情報の取得に失敗しました: ${e.toString()}');
    }
  }

  /// プレミアム会員かどうかをチェック
  ///
  /// [entitlementIdentifier] エンタイトルメント識別子（デフォルト: "premium"）
  static Future<bool> isPremium({String entitlementIdentifier = 'premium'}) async {
    try {
      final customerInfo = await getCustomerInfo();
      final entitlement = customerInfo.entitlements.all[entitlementIdentifier];
      return entitlement != null && entitlement.isActive;
    } catch (e) {
      return false;
    }
  }

  /// サブスクリプション状態を取得
  static Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final customerInfo = await getCustomerInfo();
      final premiumEntitlement = customerInfo.entitlements.all['premium'];

      if (premiumEntitlement == null || !premiumEntitlement.isActive) {
        return SubscriptionStatus(
          isActive: false,
          productIdentifier: null,
          expirationDate: null,
          willRenew: false,
        );
      }

      return SubscriptionStatus(
        isActive: true,
        productIdentifier: premiumEntitlement.productIdentifier,
        expirationDate: premiumEntitlement.expirationDate,
        willRenew: premiumEntitlement.willRenew,
      );
    } catch (e) {
      return SubscriptionStatus(
        isActive: false,
        productIdentifier: null,
        expirationDate: null,
        willRenew: false,
      );
    }
  }

  /// ユーザーIDを設定
  static Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      throw Exception('ユーザーIDの設定に失敗しました: ${e.toString()}');
    }
  }

  /// ログアウト
  static Future<void> logout() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      throw Exception('ログアウトに失敗しました: ${e.toString()}');
    }
  }
}

/// サブスクリプション状態
class SubscriptionStatus {
  final bool isActive;
  final String? productIdentifier;
  final String? expirationDate;
  final bool willRenew;

  SubscriptionStatus({
    required this.isActive,
    this.productIdentifier,
    this.expirationDate,
    this.willRenew = false,
  });

  /// プラン名を取得
  String? get planName {
    if (productIdentifier == null) return null;
    if (productIdentifier!.contains('monthly')) {
      return '月額プラン';
    } else if (productIdentifier!.contains('yearly')) {
      return '年額プラン';
    }
    return null;
  }
}
