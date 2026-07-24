import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/course_list_cubit.dart';
import '../cubit/course_list_state.dart';
import '../models/course.dart';
import '../services/course_service.dart';
import '../services/progress_service.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatelessWidget {
  final CourseService courseService;
  final ProgressService progressService;

  CourseListScreen({
    super.key,
    CourseService? courseService,
    ProgressService? progressService,
  })  : courseService = courseService ?? CourseService(),
        progressService = progressService ?? ProgressService();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CourseListCubit(
        courseService: courseService,
        progressService: progressService,
      )..loadCourses(),
      child: const _CourseListView(),
    );
  }
}

class _CourseListView extends StatelessWidget {
  const _CourseListView();

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Mini Course Player",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 3),
            Text(
              "Learn on your schedule",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<CourseListCubit, CourseListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
                    const SizedBox(height: 14),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please check your connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () => context.read<CourseListCubit>().loadCourses(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry Loading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<CourseListCubit>().loadCourses(),
            color: const Color(0xFF2563EB),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              itemCount: state.courses.length,
              itemBuilder: (context, index) {
                final course = state.courses[index];
                final fraction = state.progressByCourseId[course.id] ?? 0.0;
                final isCompleted = state.completedByCourseId[course.id] ?? false;

                return _EnhancedCourseTile(
                  course: course,
                  progressFraction: fraction,
                  isCompleted: isCompleted,
                  formatDuration: _formatDuration,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailScreen(
                          course: course,
                          progressService: context.read<CourseListCubit>().progressService,
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<CourseListCubit>().refreshProgressFor(course);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EnhancedCourseTile extends StatelessWidget {
  final Course course;
  final double progressFraction;
  final bool isCompleted;
  final String Function(int) formatDuration;
  final VoidCallback onTap;

  const _EnhancedCourseTile({
    required this.course,
    required this.progressFraction,
    required this.isCompleted,
    required this.formatDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (progressFraction * 100).round();

    return Container(
      height: 132,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: Image.network(
                  course.thumbnailUrl,
                  width: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 130,
                    color: const Color(0xFFE2E8F0),
                    child: const Icon(Icons.movie_creation_outlined, color: Color(0xFF94A3B8), size: 32),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF2563EB)),
                                const SizedBox(width: 4),
                                Text(
                                  formatDuration(course.durationSeconds),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: isCompleted ? 1.0 : progressFraction,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isCompleted ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isCompleted ? "Completed" : "$percentage%",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}