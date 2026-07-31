import 'package:flutter/foundation.dart';

enum BootstrapState { initializing, error, success }

class BootstrapViewModel extends ChangeNotifier {
  BootstrapState _state = BootstrapState.initializing;
  String _currentStep = 'Starting initialization...';
  String? _errorMessage;

  BootstrapState get state => _state;
  String get currentStep => _currentStep;
  String? get errorMessage => _errorMessage;

  void updateStep(String stepText) {
    _currentStep = stepText;
    notifyListeners();
  }

  void markError(String errorMsg) {
    _state = BootstrapState.error;
    _errorMessage = errorMsg;
    notifyListeners();
  }

  void markSuccess() {
    _state = BootstrapState.success;
    _currentStep = 'Initialization complete!';
    notifyListeners();
  }

  void reset() {
    _state = BootstrapState.initializing;
    _errorMessage = null;
    _currentStep = 'Retrying initialization...';
    notifyListeners();
  }
}
