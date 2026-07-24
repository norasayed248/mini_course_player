import 'package:shared_preferences/shared_preferences.dart';

/// Persists "how far a user got" into each course's video, keyed by course id.
class ProgressService {
  static const _keyPrefix = 'course_progress_seconds_';
  static const _completedKeyPrefix = 'course_completed_';

  /// Fraction of the video considered "done".
  static const double completionThreshold = 0.98;

  Future<void> saveProgress({
    required String courseId,
    required int positionSeconds,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (durationSeconds <= 0) return;

    final fraction = positionSeconds / durationSeconds;
    final isComplete = fraction >= completionThreshold;

    // الـ position بيترجع صفر لما الفيديو يخلص (عشان يبدأ من الأول تاني)،
    // لكن حالة "الاكتمال" بتتسجل في علامة منفصلة وثابتة، عشان تفضل
    // معروفة حتى بعد ما الـ position يترجع صفر.
    await prefs.setInt(
      _keyPrefix + courseId,
      isComplete ? 0 : positionSeconds,
    );

    await prefs.setBool(_completedKeyPrefix + courseId, isComplete);
  }

  Future<int> getSavedPositionSeconds(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPrefix + courseId) ?? 0;
  }

  /// هل الكورس اتشاف كامل قبل كده؟ ثابتة، بتفضل true حتى لو الـ position
  /// اتصفّر، ومبتتغيرش إلا بـ resetProgress().
  Future<bool> isCompleted(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKeyPrefix + courseId) ?? false;
  }

  Future<double> getProgressFraction({
    required String courseId,
    required int durationSeconds,
  }) async {
    if (durationSeconds <= 0) return 0.0;
    final saved = await getSavedPositionSeconds(courseId);
    final fraction = saved / durationSeconds;
    if (fraction.isNaN || fraction < 0) return 0.0;
    if (fraction > 1) return 1.0;
    return fraction;
  }

  Future<void> resetProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix + courseId);
    await prefs.remove(_completedKeyPrefix + courseId);
  }
}