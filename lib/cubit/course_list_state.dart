import '../models/course.dart';

class CourseListState {
  final bool isLoading;
  final String? errorMessage;
  final List<Course> courses;
  final Map<String, double> progressByCourseId;
  final Map<String, bool> completedByCourseId;

  const CourseListState({
    this.isLoading = true,
    this.errorMessage,
    this.courses = const [],
    this.progressByCourseId = const {},
    this.completedByCourseId = const {},
  });

  CourseListState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Course>? courses,
    Map<String, double>? progressByCourseId,
    Map<String, bool>? completedByCourseId,
  }) {
    return CourseListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      courses: courses ?? this.courses,
      progressByCourseId: progressByCourseId ?? this.progressByCourseId,
      completedByCourseId: completedByCourseId ?? this.completedByCourseId,
    );
  }
}