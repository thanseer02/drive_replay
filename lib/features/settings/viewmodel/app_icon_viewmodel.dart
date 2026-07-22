import 'package:flutter/material.dart';
import 'package:dynamic_app_icon/dynamic_app_icon.dart';

class AppIconViewModel extends ChangeNotifier {
  bool _isSupported = false;
  bool _initialized = false;
  String _currentIcon = 'default';
  List<String> _availableIcons = [];

  bool get isSupported => _isSupported;
  bool get initialized => _initialized;
  String get currentIcon => _currentIcon;
  List<String> get availableIcons => _availableIcons;

  AppIconViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isSupported = await DynamicAppIcon.isSupported();
    if (_isSupported) {
      _availableIcons = await DynamicAppIcon.availableIcons(); 
      final current = await DynamicAppIcon.current();
      _currentIcon = current ?? 'default';
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> changeIcon(String iconName) async {
    if (!_isSupported) return;
    
    try {
      if (iconName == 'default') {
        await DynamicAppIcon.reset();
      } else {
        await DynamicAppIcon.change(iconName);
      }
      _currentIcon = iconName;
      notifyListeners();
    } catch (e) {
      // Re-throw to be handled by the UI layer
      rethrow;
    }
  }
}
