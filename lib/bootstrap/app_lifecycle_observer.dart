import 'package:flutter/widgets.dart';
import 'package:drive_replay/core/logger/logger_service.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        LoggerService.info('App Lifecycle: Resumed (Foreground)');
        break;
      case AppLifecycleState.inactive:
        LoggerService.info('App Lifecycle: Inactive');
        break;
      case AppLifecycleState.paused:
        LoggerService.info('App Lifecycle: Paused (Background)');
        break;
      case AppLifecycleState.detached:
        LoggerService.info('App Lifecycle: Detached (Terminated)');
        break;
      case AppLifecycleState.hidden:
        LoggerService.info('App Lifecycle: Hidden');
        break;
    }
  }
}
