/// Network Info - Connectivity checking for offline-first
/// CDC: Mode hors ligne avec synchronisation
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

// ── Abstract Interface ──────────────────────────────────────

abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

// ── Implementation ──────────────────────────────────────────

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;
  final InternetConnection _internetChecker;

  NetworkInfoImpl({
    Connectivity? connectivity,
    InternetConnection? internetChecker,
  })  : _connectivity = connectivity ?? Connectivity(),
        _internetChecker = internetChecker ?? InternetConnection();

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    if (result.contains(ConnectivityResult.none)) return false;
    return await _internetChecker.hasInternetAccess;
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.asyncMap((results) async {
      if (results.contains(ConnectivityResult.none)) return false;
      return await _internetChecker.hasInternetAccess;
    });
  }
}

// ── Providers ───────────────────────────────────────────────

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

/// Stream provider for real-time connectivity status
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
});
