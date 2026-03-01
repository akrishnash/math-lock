import 'dart:typed_data';

/// Represents an installed app that can be blocked.
class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.label,
    this.iconBytes,
  });

  final String packageName;
  final String label;
  final Uint8List? iconBytes;

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'label': label,
        if (iconBytes != null) 'icon': iconBytes,
      };

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    final dynamic rawIcon = json['icon'];
    Uint8List? icon;
    if (rawIcon is Uint8List) {
      icon = rawIcon;
    } else if (rawIcon is List) {
      icon = Uint8List.fromList(rawIcon.cast<int>());
    }
    return AppInfo(
      packageName: json['packageName'] as String,
      label: json['label'] as String,
      iconBytes: icon,
    );
  }
}
