class SettingsModel {
  final bool isDarkMode;
  final bool useMetric;

  SettingsModel({
    required this.isDarkMode,
    required this.useMetric,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'is_dark_mode': isDarkMode ? 1 : 0,
      'use_metric': useMetric ? 1 : 0,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      isDarkMode: (map['is_dark_mode'] as int? ?? 0) == 1,
      useMetric: (map['use_metric'] as int? ?? 1) == 1,
    );
  }
}
