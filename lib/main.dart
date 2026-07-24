import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: GoogleFonts.cairo().fontFamily,
        textTheme: GoogleFonts.cairoTextTheme(),
      ),
      home: CourseListScreen(),
    );
  }
}