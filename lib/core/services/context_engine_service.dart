import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum AppNetworkStrength { weak, medium, strong }

class UserContextState {
  final AppNetworkStrength networkStrength;
  final bool isInMotion;

  const UserContextState({
    required this.networkStrength,
    required this.isInMotion,
  });

  @override
  String toString() => 'Context(Network: ${networkStrength.name}, InMotion: $isInMotion)';
}

class ContextEngineService {
  final _connectivity = Connectivity();
  StreamController<UserContextState>? _contextStreamController;
  StreamSubscription? _networkSubscription;
  StreamSubscription? _sensorSubscription;

  // Track state memory caches
  AppNetworkStrength _currentNetwork = AppNetworkStrength.weak;
  bool _currentMotionState = false;

  /// Expose the unified ambient state stream to the UI
  Stream<UserContextState> get contextStream {
    _contextStreamController ??= StreamController<UserContextState>.broadcast(
      onListen: _startListening,
      onCancel: _stopListening,
    );
    return _contextStreamController!.stream;
  }

  void _startListening() {
    // 1. Intercept Network profile changes
    _networkSubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isEmpty || results.contains(ConnectivityResult.none)) {
        _currentNetwork = AppNetworkStrength.weak;
      } else if (results.contains(ConnectivityResult.wifi)) {
        _currentNetwork = AppNetworkStrength.strong;
      } else {
        // Mobile cellular networks (LTE/3G/4G) map to intermediate settings
        _currentNetwork = AppNetworkStrength.medium;
      }
      _emitNewContext();
    });

    // 2. Intercept User motion changes via Accelerometer vector magnitude
    _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calculate total force vector: Magnitude = sqrt(x² + y² + z²)
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      // When stationary, magnitude stays near Earth's gravitational constant (~9.81 m/s²)
      // Spikes above 13.0 m/s² indicate rhythmic kinetic steps (walking/running)
      final bool motionDetected = magnitude > 13.0;

      if (motionDetected != _currentMotionState) {
        _currentMotionState = motionDetected;
        _emitNewContext();
      }
    });
  }

  void _emitNewContext() {
    if (_contextStreamController != null && !_contextStreamController!.isClosed) {
      _contextStreamController!.add(
        UserContextState(
          networkStrength: _currentNetwork,
          isInMotion: _currentMotionState,
        ),
      );
    }
  }

  void _stopListening() {
    _networkSubscription?.cancel();
    _sensorSubscription?.cancel();
    _contextStreamController?.close();
    _contextStreamController = null;
  }
}
