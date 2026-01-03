import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../models/store.dart';
import '../repositories/receipt_repository.dart';

/// ReceiptRepositoryのプロバイダー
final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository();
});

/// 領収書一覧を取得するFutureProvider
final receiptsListProvider = FutureProvider.family<List<Receipt>, ReceiptListParams>(
  (ref, params) async {
    final receiptRepository = ref.watch(receiptRepositoryProvider);
    return await receiptRepository.getReceipts(
      userId: params.userId,
      storeId: params.storeId,
    );
  },
);

/// 領収書一覧パラメータ
class ReceiptListParams {
  final String userId;
  final String storeId;

  ReceiptListParams({required this.userId, required this.storeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptListParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          storeId == other.storeId;

  @override
  int get hashCode => userId.hashCode ^ storeId.hashCode;
}

/// 領収書詳細を取得するFutureProvider
final receiptDetailProvider = FutureProvider.family<Receipt?, ReceiptParams>(
  (ref, params) async {
    final receiptRepository = ref.watch(receiptRepositoryProvider);
    return await receiptRepository.getReceipt(
      params.userId,
      params.storeId,
      params.receiptId,
    );
  },
);

/// 領収書パラメータ
class ReceiptParams {
  final String userId;
  final String storeId;
  final String receiptId;

  ReceiptParams({
    required this.userId,
    required this.storeId,
    required this.receiptId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          storeId == other.storeId &&
          receiptId == other.receiptId;

  @override
  int get hashCode => userId.hashCode ^ storeId.hashCode ^ receiptId.hashCode;
}

/// 領収書コントローラー（領収書関連の操作を行う）
class ReceiptController extends StateNotifier<AsyncValue<Receipt?>> {
  final ReceiptRepository _receiptRepository;

  ReceiptController(this._receiptRepository)
      : super(const AsyncValue.data(null));

  /// 領収書を作成
  Future<Receipt?> createReceipt({
    required Store store,
    required String recipientName,
    required String memo,
    required int totalAmount,
    required double taxRate,
    Uint8List? stampImageBytes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final receipt = await _receiptRepository.createReceipt(
        store: store,
        recipientName: recipientName,
        memo: memo,
        totalAmount: totalAmount,
        taxRate: taxRate,
        stampImageBytes: stampImageBytes,
      );

      state = AsyncValue.data(receipt);
      return receipt;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// 領収書を削除
  Future<void> deleteReceipt(String userId, String storeId, String receiptId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _receiptRepository.deleteReceipt(userId, storeId, receiptId);
      return null;
    });
  }

  /// 状態をクリア
  void clear() {
    state = const AsyncValue.data(null);
  }
}

/// ReceiptControllerのプロバイダー
final receiptControllerProvider =
    StateNotifierProvider<ReceiptController, AsyncValue<Receipt?>>((ref) {
  final receiptRepository = ref.watch(receiptRepositoryProvider);
  return ReceiptController(receiptRepository);
});

/// 領収書検索コントローラー
class ReceiptSearchController
    extends StateNotifier<AsyncValue<List<Receipt>>> {
  final ReceiptRepository _receiptRepository;
  final String _userId;
  final String _storeId;

  ReceiptSearchController(this._receiptRepository, this._userId, this._storeId)
      : super(const AsyncValue.loading()) {
    _loadReceipts();
  }

  /// 領収書一覧を読み込み
  Future<void> _loadReceipts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _receiptRepository.getReceipts(
        userId: _userId,
        storeId: _storeId,
      );
    });
  }

  /// 領収書を検索
  Future<void> searchReceipts({
    DateTime? startDate,
    DateTime? endDate,
    String? recipientName,
    int? minAmount,
    int? maxAmount,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _receiptRepository.searchReceipts(
        userId: _userId,
        storeId: _storeId,
        startDate: startDate,
        endDate: endDate,
        recipientName: recipientName,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
    });
  }

  /// 領収書一覧をリフレッシュ
  Future<void> refresh() async {
    await _loadReceipts();
  }
}

/// 領収書検索パラメータ
class ReceiptSearchParams {
  final String userId;
  final String storeId;

  ReceiptSearchParams({required this.userId, required this.storeId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptSearchParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          storeId == other.storeId;

  @override
  int get hashCode => userId.hashCode ^ storeId.hashCode;
}

/// ReceiptSearchControllerのプロバイダー
final receiptSearchControllerProvider = StateNotifierProvider.family<
    ReceiptSearchController, AsyncValue<List<Receipt>>, ReceiptSearchParams>(
  (ref, params) {
    final receiptRepository = ref.watch(receiptRepositoryProvider);
    return ReceiptSearchController(receiptRepository, params.userId, params.storeId);
  },
);
