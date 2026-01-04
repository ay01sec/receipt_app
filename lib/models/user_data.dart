import 'package:cloud_firestore/cloud_firestore.dart';

/// ユーザーデータモデル
class UserData {
  final String id; // ユーザーID（Firebase AuthのUID）
  final String email; // メールアドレス
  final DateTime createdAt; // アカウント作成日時
  final DateTime updatedAt; // 更新日時
  final String? subscriptionPlan; // サブスクリプションプラン（monthly, yearly, null）
  final String? subscriptionStatus; // サブスク状態（active, expired, cancelled）
  final DateTime? subscriptionStartDate; // サブスク開始日
  final DateTime? subscriptionEndDate; // サブスク終了日
  final bool? autoRenew; // 自動更新設定

  UserData({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.autoRenew,
  });

  /// Firestoreドキュメントからユーザーオブジェクトを作成
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      id: doc.id,
      email: data['email'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      subscriptionPlan: data['subscriptionPlan'],
      subscriptionStatus: data['subscriptionStatus'],
      subscriptionStartDate: data['subscriptionStartDate'] != null
          ? (data['subscriptionStartDate'] as Timestamp).toDate()
          : null,
      subscriptionEndDate: data['subscriptionEndDate'] != null
          ? (data['subscriptionEndDate'] as Timestamp).toDate()
          : null,
      autoRenew: data['autoRenew'],
    );
  }

  /// Firestoreに保存する形式に変換
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (subscriptionPlan != null) 'subscriptionPlan': subscriptionPlan,
      if (subscriptionStatus != null) 'subscriptionStatus': subscriptionStatus,
      if (subscriptionStartDate != null)
        'subscriptionStartDate': Timestamp.fromDate(subscriptionStartDate!),
      if (subscriptionEndDate != null)
        'subscriptionEndDate': Timestamp.fromDate(subscriptionEndDate!),
      if (autoRenew != null) 'autoRenew': autoRenew,
    };
  }

  /// コピーメソッド
  UserData copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionPlan,
    String? subscriptionStatus,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? autoRenew,
  }) {
    return UserData(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }

  /// プレミアム会員かどうかをチェック
  bool get isPremium {
    if (subscriptionStatus == null) return false;
    if (subscriptionStatus != 'active') return false;
    if (subscriptionEndDate == null) return false;
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  /// サブスクが有効かどうかをチェック
  bool get hasActiveSubscription {
    return isPremium;
  }

  /// 無料トライアル期間中かどうかをチェック（3日間）
  bool get isInTrial {
    final now = DateTime.now();
    final trialEndDate = createdAt.add(const Duration(days: 3));
    return now.isBefore(trialEndDate);
  }

  /// トライアル残り日数を取得（0-3日）
  int get trialDaysRemaining {
    if (!isInTrial) return 0;
    final now = DateTime.now();
    final trialEndDate = createdAt.add(const Duration(days: 3));
    final difference = trialEndDate.difference(now);
    return difference.inDays + 1; // 当日も含めるため+1
  }

  /// アプリを使用可能かどうか（トライアル中 or サブスク有効）
  bool get canUseApp {
    return isInTrial || hasActiveSubscription;
  }

  /// 課金画面を表示すべきかどうか
  bool get shouldShowPaywall {
    return !isInTrial && !hasActiveSubscription;
  }
}
