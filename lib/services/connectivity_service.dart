import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Stream to listen to connectivity changes
  Stream<bool> get connectivityStream => _connectivity.onConnectivityChanged
      .map((List<ConnectivityResult> results) {
        print('Connectivity results: $results');
        _isConnected = results.any(
          (result) =>
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.wifi ||
              result == ConnectivityResult.ethernet ||
              result == ConnectivityResult.bluetooth,
        );
        print('Is connected: $_isConnected');
        return _isConnected;
      });

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    print('Initial connectivity results: $results');
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.bluetooth,
    );
    print('Initial connection state: $_isConnected');

    // Start listening to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _isConnected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.bluetooth,
      );
    });
  }

  // Check current connectivity status
  Future<bool> checkConnectivity() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    _isConnected = results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.bluetooth,
    );
    return _isConnected;
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
