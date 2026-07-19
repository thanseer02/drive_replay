class ServiceLocator {
  static final Map<Type, Object> _services = {};

  // Register a singleton service
  static void register<T extends Object>(T service) {
    _services[T] = service;
  }

  // Check if service is registered
  static bool isRegistered<T extends Object>() {
    return _services.containsKey(T);
  }

  // Retrieve service
  static T get<T extends Object>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service of type $T not registered in locator');
    }
    return service as T;
  }

  // Clear all for resetting/testing
  static void clear() {
    _services.clear();
  }
}
