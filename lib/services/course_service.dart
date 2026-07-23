import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/course.dart';

/// Loads the course catalogue.
///
/// In a real app this would hit a backend; here we load from a bundled
/// JSON asset, but the method signature is what matters for testability -
/// screens depend on this abstraction, not on "asset loading" directly,
/// so it can be swapped for a fake in widget tests.
class CourseService {
  Future<List<Course>> loadCourses() async {
    final raw = await rootBundle.loadString('assets/courses.json');
    final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> list = decoded['courses'] as List<dynamic>;
    return list
        .map((e) => Course.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
