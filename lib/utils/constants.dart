// アプリ情報
class AppConstants {
  static const String appName = '領収書アプリ';
  static const String appVersion = '1.0.0';
}

// Firebase Firestoreコレクション名
class FirestoreCollections {
  static const String users = 'users';
  static const String stores = 'stores';
  static const String receipts = 'receipts';
  static const String subscriptions = 'subscriptions';
}

// Firebase Storageパス
class StoragePaths {
  static const String receipts = 'receipts';
  static const String stamps = 'stamps';

  /// 領収書PDFのパスを生成
  static String receiptPdfPath(String storeId, String receiptId) {
    return '$receipts/$storeId/$receiptId.pdf';
  }

  /// 印鑑画像のパスを生成
  static String stampImagePath(String storeId) {
    return '$stamps/$storeId/stamp.png';
  }
}

// 領収書ステータス
class ReceiptStatus {
  static const String draft = 'draft'; // 下書き
  static const String issued = 'issued'; // 発行済み
  static const String deleted = 'deleted'; // 削除済み
}

// RevenueCat設定
class RevenueCatConfig {
  /// RevenueCat Public API Key (iOS)
  /// 取得方法: RevenueCat Dashboard → Settings → API keys
  static const String apiKey = 'appl_lbdAHRSrRakbAuSbozGRBXydGjR';

  /// Entitlement ID（権限ID）
  static const String entitlementId = 'premium';

  /// Product IDs（RevenueCatで作成した商品ID）
  static const String monthlyProductId = 'receipt_monthly';
  static const String premiumProductId = 'receipt_premium';
  static const String businessProductId = 'receipt_business';
}

// サブスクリプションプラン
class SubscriptionPlans {
  static const String monthly = 'monthly'; // 月額プラン
  static const String premium = 'premium'; // プレミアムプラン（旧：年額）
  static const String business = 'business'; // ビジネスプラン

  // プラン価格（円）※App Store Connectで実際の価格を設定
  static const int monthlyPrice = 1000;
  static const int premiumPrice = 5000;
  static const int businessPrice = 10000;
}

// サブスクリプション状態
class SubscriptionStatus {
  static const String active = 'active'; // 有効
  static const String expired = 'expired'; // 期限切れ
  static const String cancelled = 'cancelled'; // キャンセル済み
}

// 税率
class TaxRates {
  static const double standard = 10.0; // 標準税率（10%）
  static const double reduced = 8.0; // 軽減税率（8%）

  /// 税込金額から税抜金額を計算
  static int calculateSubtotal(int totalAmount, double taxRate) {
    return (totalAmount / (1 + taxRate / 100)).round();
  }

  /// 税抜金額から消費税額を計算
  static int calculateTax(int subtotalAmount, double taxRate) {
    return (subtotalAmount * taxRate / 100).round();
  }

  /// 税抜金額から税込金額を計算
  static int calculateTotal(int subtotalAmount, double taxRate) {
    return subtotalAmount + calculateTax(subtotalAmount, taxRate);
  }
}

// UI関連
class UIConstants {
  // パディング
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  // ボーダー半径
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;

  // アイコンサイズ
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}

// バリデーション
class ValidationConstants {
  // メールアドレス
  static const int emailMaxLength = 100;

  // パスワード
  static const int passwordMinLength = 8;
  static const int passwordMaxLength = 50;

  // 店舗情報
  static const int storeNameMaxLength = 50;
  static const int addressMaxLength = 100;
  static const int phoneNumberMaxLength = 15;
  static const int invoiceNumberMaxLength = 14; // T + 13桁

  // 領収書
  static const int recipientNameMaxLength = 50;
  static const int memoMaxLength = 100;
  static const int maxAmount = 999999999; // 最大金額（9億9999万9999円）
}

// エラーメッセージ
class ErrorMessages {
  // 認証
  static const String emailRequired = 'メールアドレスを入力してください';
  static const String emailInvalid = '有効なメールアドレスを入力してください';
  static const String passwordRequired = 'パスワードを入力してください';
  static const String passwordTooShort = 'パスワードは8文字以上で入力してください';
  static const String passwordMismatch = 'パスワードが一致しません';

  // 店舗情報
  static const String storeNameRequired = '店舗名を入力してください';
  static const String addressRequired = '住所を入力してください';
  static const String phoneNumberRequired = '電話番号を入力してください';
  static const String phoneNumberInvalid = '有効な電話番号を入力してください';
  static const String invoiceNumberInvalid = '有効なインボイス番号を入力してください（T + 13桁）';

  // 領収書
  static const String recipientNameRequired = '宛名を入力してください';
  static const String memoRequired = '但し書きを入力してください';
  static const String amountRequired = '金額を入力してください';
  static const String amountInvalid = '有効な金額を入力してください';
  static const String amountTooLarge = '金額が大きすぎます';

  // 一般
  static const String networkError = 'ネットワークエラーが発生しました';
  static const String unknownError = '予期しないエラーが発生しました';
}

// 成功メッセージ
class SuccessMessages {
  static const String loginSuccess = 'ログインしました';
  static const String logoutSuccess = 'ログアウトしました';
  static const String accountCreated = 'アカウントを作成しました';
  static const String receiptCreated = '領収書を作成しました';
  static const String storeSaved = '店舗情報を保存しました';
  static const String passwordChanged = 'パスワードを変更しました';
}
