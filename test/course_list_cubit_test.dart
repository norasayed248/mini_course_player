import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_course_player/cubit/course_list_cubit.dart';
import 'package:mini_course_player/models/course.dart';
import 'package:mini_course_player/services/course_service.dart';
import 'package:mini_course_player/services/progress_service.dart';

/// فيك سيرفس وهمي يرجع بيانات ثابتة، من غير ما يحتاج asset bundle حقيقي.
class _FakeCourseService extends CourseService {
  @override
  Future<List<Course>> loadCourses() async {
    return const [
      Course(
        id: 'c001',
        title: 'Intro to UI/UX Design',
        thumbnailUrl: 'https://example.com/thumb1.jpg',
        durationSeconds: 30,
        description: 'desc',
        videoUrl: 'https://example.com/video1.mp4',
      ),
      Course(
        id: 'c002',
        title: 'Digital Marketing Basics',
        thumbnailUrl: 'https://example.com/thumb2.jpg',
        durationSeconds: 30,
        description: 'desc',
        videoUrl: 'https://example.com/video2.mp4',
      ),
    ];
  }
}

/// سيرفس بيرمي error، عشان نختبر حالة الفشل من غير ما نعتمد على شبكة حقيقية.
class _FailingCourseService extends CourseService {
  @override
  Future<List<Course>> loadCourses() async {
    throw Exception('network error');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CourseListCubit', () {
    test('initial state is loading with no courses', () {
      final cubit = CourseListCubit(
        courseService: _FakeCourseService(),
        progressService: ProgressService(),
      );

      expect(cubit.state.isLoading, true);
      expect(cubit.state.courses, isEmpty);
      expect(cubit.state.errorMessage, isNull);
    });

    test('loadCourses populates courses and clears loading', () async {
      final cubit = CourseListCubit(
        courseService: _FakeCourseService(),
        progressService: ProgressService(),
      );

      await cubit.loadCourses();

      expect(cubit.state.isLoading, false);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.courses.length, 2);
      expect(cubit.state.courses.first.title, 'Intro to UI/UX Design');
    });

    test('loadCourses populates a progress fraction per course', () async {
      final progressService = ProgressService();
      await progressService.saveProgress(
        courseId: 'c001',
        positionSeconds: 15,
        durationSeconds: 30,
      );

      final cubit = CourseListCubit(
        courseService: _FakeCourseService(),
        progressService: progressService,
      );

      await cubit.loadCourses();

      expect(cubit.state.progressByCourseId['c001'], closeTo(0.5, 0.001));
      expect(cubit.state.progressByCourseId['c002'], 0.0);
    });

    test('loadCourses sets an error message when the service throws', () async {
      final cubit = CourseListCubit(
        courseService: _FailingCourseService(),
        progressService: ProgressService(),
      );

      await cubit.loadCourses();

      expect(cubit.state.isLoading, false);
      expect(cubit.state.errorMessage, isNotNull);
      expect(cubit.state.courses, isEmpty);
    });

    test('refreshProgressFor updates only the given course\'s fraction', () async {
      final progressService = ProgressService();
      final cubit = CourseListCubit(
        courseService: _FakeCourseService(),
        progressService: progressService,
      );

      await cubit.loadCourses();
      expect(cubit.state.progressByCourseId['c001'], 0.0);

      // المستخدم شاف نص الفيديو بعد ما فتح شاشة التفاصيل...
      // المستخدم شاف جزء من الفيديو (مش لحد الآخر) بعد ما فتح شاشة التفاصيل...
      await progressService.saveProgress(
        courseId: 'c001',
        positionSeconds: 20,
        durationSeconds: 30,
      );

      await cubit.refreshProgressFor(cubit.state.courses.first);

      expect(cubit.state.progressByCourseId['c001'], closeTo(20 / 30, 0.001));
      // c002 المفروض يفضل زي ما هو من غير تغيير
      expect(cubit.state.progressByCourseId['c002'], 0.0);
    });
  });
}