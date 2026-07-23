import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_course_player/models/course.dart';
import 'package:mini_course_player/services/course_service.dart';
import 'package:mini_course_player/services/progress_service.dart';
import 'package:mini_course_player/screens/course_list_screen.dart';

/// فيك سيرفس بيرجع بيانات ثابتة، عشان الـ widget test ميعتمدش على asset
/// bundle حقيقي أو اتصال إنترنت.
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows a loading indicator then the course titles',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseListScreen(
          courseService: _FakeCourseService(),
          progressService: ProgressService(),
        ),
      ),
    );

    // أول فريم لسه بيحمّل - المفروض يظهر الـ spinner.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // نستنى الـ Cubit يخلص تحميل البيانات.
    await tester.pumpAndSettle();

    expect(find.text('Intro to UI/UX Design'), findsOneWidget);
    expect(find.text('Digital Marketing Basics'), findsOneWidget);
  });

  testWidgets('shows 0% progress for a course with no saved position',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseListScreen(
          courseService: _FakeCourseService(),
          progressService: ProgressService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('0%'), findsNWidgets(2));
  });
}