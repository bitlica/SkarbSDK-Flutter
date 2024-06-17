abstract class SkarbLogger {
  void logEvent({required SkarbEventType eventType, String? message});
}

enum SkarbEventType { info, error, verbose }
