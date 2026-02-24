/// Represents an installed app that can be blocked.
class AppInfo {
  const AppInfo({
    required this.packageName,
    required this.label,
  });

  final String packageName;
  final String label;

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'label': label,
      };

  factory AppInfo.fromJson(Map<String, dynamic> json) => AppInfo(
        packageName: json['packageName'] as String,
        label: json['label'] as String,
      );
}
