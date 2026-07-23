import 'package:flutter/material.dart';
import 'screens/course_list_screen.dart';

void main() {
  runApp(const MiniCoursePlayerApp());
}

class MiniCoursePlayerApp extends StatelessWidget {
  const MiniCoursePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Course Player',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: CourseListScreen(),
    );
  }
}
