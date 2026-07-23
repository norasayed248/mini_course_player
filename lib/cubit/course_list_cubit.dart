import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/progress_service.dart';
import 'course_list_state.dart';

class CourseListCubit extends Cubit<CourseListState> {
  final CourseService courseService;
  final ProgressService progressService;

  CourseListCubit({
    required this.courseService,
    required this.progressService,
  }) : super(const CourseListState());

  Future<void> loadCourses() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final courses = await courseService.loadCourses();

      final progressMap = <String, double>{};
      final completedMap = <String, bool>{};
      for (final course in courses) {
        progressMap[course.id] = await progressService.getProgressFraction(
          courseId: course.id,
          durationSeconds: course.durationSeconds,
        );
        completedMap[course.id] = await progressService.isCompleted(course.id);
      }

      emit(state.copyWith(
        isLoading: false,
        courses: courses,
        progressByCourseId: progressMap,
        completedByCourseId: completedMap,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load course catalogue',
      ));
    }
  }

  Future<void> refreshProgressFor(Course course) async {
    final fraction = await progressService.getProgressFraction(
      courseId: course.id,
      durationSeconds: course.durationSeconds,
    );
    final isCompleted = await progressService.isCompleted(course.id);

    final updatedProgress = Map<String, double>.from(state.progressByCourseId);
    updatedProgress[course.id] = fraction;

    final updatedCompleted = Map<String, bool>.from(state.completedByCourseId);
    updatedCompleted[course.id] = isCompleted;

    emit(state.copyWith(
      progressByCourseId: updatedProgress,
      completedByCourseId: updatedCompleted,
    ));
  }
}