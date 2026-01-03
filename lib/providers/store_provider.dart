import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';
import '../repositories/store_repository.dart';
import 'auth_provider.dart';

/// StoreRepositoryのプロバイダー
final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository();
});

/// 現在のユーザーの店舗情報を取得するFutureProvider
final currentStoreProvider = FutureProvider<Store?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final storeRepository = ref.watch(storeRepositoryProvider);
  return await storeRepository.getStore(user.uid);
});

/// 店舗コントローラー（店舗関連の操作を行う）
class StoreController extends StateNotifier<AsyncValue<Store?>> {
  final StoreRepository _storeRepository;
  final String? _userId;

  StoreController(this._storeRepository, this._userId)
      : super(const AsyncValue.loading()) {
    _loadStore();
  }

  /// 店舗情報を読み込み
  Future<void> _loadStore() async {
    if (_userId == null) {
      print('🔴 StoreController: userId is null, user not authenticated');
      state = const AsyncValue.data(null);
      return;
    }

    print('🟢 StoreController: Loading store for userId: $_userId');
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final store = await _storeRepository.getStore(_userId);
      print('🟢 StoreController: Store loaded: ${store?.id ?? "null"}');
      return store;
    });

    if (state.hasError) {
      print('🔴 StoreController: Error loading store: ${state.error}');
    }
  }

  /// 店舗情報を作成
  Future<void> createStore({
    required String storeName,
    required String storeAddress1,
    String storeAddress2 = '',
    required String phoneNumber,
    required String invoiceNumber,
    required String defaultMemo,
    String? stampImagePath,
  }) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _storeRepository.createStore(
        userId: _userId,
        storeName: storeName,
        storeAddress1: storeAddress1,
        storeAddress2: storeAddress2,
        phoneNumber: phoneNumber,
        invoiceNumber: invoiceNumber,
        defaultMemo: defaultMemo,
        stampImagePath: stampImagePath,
      );
    });
  }

  /// 店舗情報を更新
  Future<void> updateStore({
    required String storeId,
    String? storeName,
    String? storeAddress1,
    String? storeAddress2,
    String? phoneNumber,
    String? invoiceNumber,
    String? defaultMemo,
    String? stampImagePath,
  }) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _storeRepository.updateStore(
        userId: _userId,
        storeId: storeId,
        storeName: storeName,
        storeAddress1: storeAddress1,
        storeAddress2: storeAddress2,
        phoneNumber: phoneNumber,
        invoiceNumber: invoiceNumber,
        defaultMemo: defaultMemo,
        stampImagePath: stampImagePath,
      );
    });
  }

  /// 領収書番号をインクリメント
  Future<void> incrementReceiptNumber(String storeId) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    await _storeRepository.incrementReceiptNumber(_userId, storeId);
    await _loadStore();
  }

  /// 店舗情報を削除
  Future<void> deleteStore(String storeId) async {
    if (_userId == null) {
      throw Exception('ユーザーがログインしていません');
    }

    state = const AsyncValue.loading();
    await _storeRepository.deleteStore(_userId, storeId);
    state = const AsyncValue.data(null);
  }

  /// 店舗情報を再読み込み
  Future<void> refresh() async {
    await _loadStore();
  }
}

/// StoreControllerのプロバイダー
final storeControllerProvider =
    StateNotifierProvider<StoreController, AsyncValue<Store?>>((ref) {
  final storeRepository = ref.watch(storeRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  print('🔵 storeControllerProvider: authState = ${authState.toString()}, user = ${user?.uid ?? "null"}');
  return StoreController(storeRepository, user?.uid);
});
