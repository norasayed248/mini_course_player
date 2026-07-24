import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/course.dart';
import '../services/progress_service.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final ProgressService progressService;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.progressService,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Timer? _saveTimer;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _controller?.pause();
      _savePosition();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final videoUrl = widget.course.videoUrl;
    final controller = videoUrl.startsWith('assets/')
        ? VideoPlayerController.asset(videoUrl)
        : VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _controller = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 15));

      final savedSeconds =
          await widget.progressService.getSavedPositionSeconds(widget.course.id);
      if (savedSeconds > 0) {
        await controller.seekTo(Duration(seconds: savedSeconds));
      }

      controller.addListener(_onControllerUpdate);

      if (!mounted) return;
      setState(() => _isLoading = false);
      controller.play();

      _saveTimer = Timer.periodic(const Duration(seconds: 3), (_) => _savePosition());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onControllerUpdate() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.hasError && !_hasError) {
      setState(() => _hasError = true);
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
    _savePosition();
  }

  Future<void> _savePosition() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    await widget.progressService.saveProgress(
      courseId: widget.course.id,
      positionSeconds: controller.value.position.inSeconds,
      durationSeconds: widget.course.durationSeconds,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTimer?.cancel();
    _savePosition();
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          widget.course.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildPlayerArea(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.course.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.course.description,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3.5),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black12,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 10),
              const Text(
                'Failed to load video.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _initializePlayer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),

          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return AnimatedOpacity(
                opacity: value.isPlaying ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              );
            },
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 6,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                padding: EdgeInsets.zero,
                colors: const VideoProgressColors(
                  playedColor: Colors.blue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.black26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}