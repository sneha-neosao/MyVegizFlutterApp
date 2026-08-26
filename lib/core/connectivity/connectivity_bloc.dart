import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import './connectivity_event.dart';
import './connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  Timer? _disconnectionTimer;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    WidgetsBinding.instance.addObserver(this);

    on<ConnectivityChanged>((event, emit) {
      if (event.isConnected) {
        _disconnectionTimer?.cancel();
        _disconnectionTimer = null;
        emit(ConnectivityConnected());
      } else {
        emit(ConnectivityDisconnected());
      }
    });

    on<CheckConnectivity>((event, emit) async {
      final results = await _connectivity.checkConnectivity();
      final isConnected = results.any((result) => result != ConnectivityResult.none);
      
      if (isConnected) {
        _disconnectionTimer?.cancel();
        _disconnectionTimer = null;
        emit(ConnectivityConnected());
      } else {
        if (!_isAppInForeground) return;
        emit(ConnectivityDisconnected());
      }
    });

    // Listen to real-time changes using connectivity_plus as primary trigger
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final isConnected = results.any((result) => result != ConnectivityResult.none);
      
      if (isConnected) {
        _disconnectionTimer?.cancel();
        _disconnectionTimer = null;
        add(const ConnectivityChanged(true));
      } else {
        if (!_isAppInForeground) return;
        
        // If we are already showing the disconnected screen or a timer is running, do nothing.
        if (state is ConnectivityDisconnected) return;
        if (_disconnectionTimer != null) return;

        // Start a 2-second debounce timer to filter out transient connection state changes
        _disconnectionTimer = Timer(const Duration(seconds: 2), () async {
          _disconnectionTimer = null;
          final currentResults = await _connectivity.checkConnectivity();
          final stillDisconnected = currentResults.every((result) => result == ConnectivityResult.none);
          
          if (stillDisconnected && _isAppInForeground) {
            add(const ConnectivityChanged(false));
          }
        });
      }
    });

    // Initial check
    add(CheckConnectivity());
  }

  bool get _isAppInForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-verify connectivity immediately when app returns to foreground
      add(CheckConnectivity());
    } else {
      // Cancel the disconnection timer if the app goes to background
      _disconnectionTimer?.cancel();
      _disconnectionTimer = null;
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _disconnectionTimer?.cancel();
    return super.close();
  }
}
