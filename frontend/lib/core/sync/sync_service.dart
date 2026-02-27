import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// Connectivity state provider
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Whether the device is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (results) =>
        results.isNotEmpty && !results.contains(ConnectivityResult.none),
    loading: () => true,
    error: (_, __) => false,
  );
});

/// Sync status
enum SyncStatus { idle, syncing, synced, error }

/// Service responsible for offline-first synchronization
class SyncService {
  final Logger _logger = Logger();
  final List<SyncOperation> _pendingOperations = [];
  bool _isSyncing = false;

  /// Queue an operation for sync when online
  void queueOperation(SyncOperation operation) {
    _pendingOperations.add(operation);
    _logger.i(
        'Queued sync operation: ${operation.type} (${_pendingOperations.length} pending)');
  }

  /// Attempt to sync all pending operations
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
          synced: 0, failed: 0, pending: _pendingOperations.length);
    }

    _isSyncing = true;
    int synced = 0;
    int failed = 0;

    final operations = List<SyncOperation>.from(_pendingOperations);

    for (final op in operations) {
      try {
        await op.execute();
        _pendingOperations.remove(op);
        synced++;
      } catch (e) {
        _logger.e('Sync failed for ${op.type}: $e');
        op.retryCount++;
        if (op.retryCount >= op.maxRetries) {
          _pendingOperations.remove(op);
          failed++;
        }
      }
    }

    _isSyncing = false;
    _logger.i('Sync complete: $synced synced, $failed failed, '
        '${_pendingOperations.length} pending');

    return SyncResult(
        synced: synced, failed: failed, pending: _pendingOperations.length);
  }

  int get pendingCount => _pendingOperations.length;
  bool get hasPending => _pendingOperations.isNotEmpty;
}

class SyncOperation {
  final String type;
  final String id;
  final Future<void> Function() execute;
  final DateTime createdAt;
  int retryCount;
  final int maxRetries;

  SyncOperation({
    required this.type,
    required this.id,
    required this.execute,
    DateTime? createdAt,
    this.retryCount = 0,
    this.maxRetries = 3,
  }) : createdAt = createdAt ?? DateTime.now();
}

class SyncResult {
  final int synced;
  final int failed;
  final int pending;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.pending,
  });
}

/// Provider for sync service
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Provider for sync status
final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  final notifier = SyncStatusNotifier(syncService);

  // Auto-sync when going online
  if (isOnline && syncService.hasPending) {
    notifier.sync();
  }

  return notifier;
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final SyncService _syncService;

  SyncStatusNotifier(this._syncService) : super(SyncStatus.idle);

  Future<void> sync() async {
    if (state == SyncStatus.syncing) return;

    state = SyncStatus.syncing;
    try {
      final result = await _syncService.syncAll();
      state = result.pending == 0 ? SyncStatus.synced : SyncStatus.idle;
    } catch (e) {
      state = SyncStatus.error;
    }
  }
}
