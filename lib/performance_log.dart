import 'dart:convert';

class PerformanceLog {
  final String method;
  final int duration;

  PerformanceLog({
    required this.method,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'duration': duration,
      };

  Map<String, String> toMapString() => {
        'method': method,
        'duration': duration.toString(),
      };

  factory PerformanceLog.fromJson(Map<String, dynamic> json) {
    return PerformanceLog(
      method: json['method'] as String,
      duration: json['duration'] as int,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory PerformanceLog.fromJsonString(String jsonString) =>
      PerformanceLog.fromJson(jsonDecode(jsonString));
}
