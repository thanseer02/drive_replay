import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  SensorService();
  
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  /// Expose raw streams for ViewModels to consume directly if needed
  Stream<UserAccelerometerEvent> get accelerometerStream => userAccelerometerEventStream();
  Stream<GyroscopeEvent> get gyroscopeStream => gyroscopeEventStream();

  /// Starts listening to sensor events. 
  /// Useful for detecting harsh braking, rapid acceleration, or crashes.
  void startListening({
    Function(UserAccelerometerEvent)? onAccelerometerEvent,
    Function(GyroscopeEvent)? onGyroscopeEvent,
  }) {
    if (onAccelerometerEvent != null) {
      _accelSubscription = userAccelerometerEventStream().listen(onAccelerometerEvent);
    }
    if (onGyroscopeEvent != null) {
      _gyroSubscription = gyroscopeEventStream().listen(onGyroscopeEvent);
    }
  }

  /// Stops listening to active sensor subscriptions to save battery.
  void stopListening() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }
}
