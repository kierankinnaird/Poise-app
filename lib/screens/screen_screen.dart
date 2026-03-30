// ignore_for_file: avoid_print
// The live camera screen. I start the camera feed immediately during the
// countdown so the preview is live before analysis begins. On simulator
// I show a placeholder because MLKit pose detection requires a real device.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../analysis/landmark_smoother.dart';
import '../analysis/squat_analyser.dart';
import '../models/fault.dart';
import '../models/screen_result.dart';
import '../theme/app_theme.dart';
import '../widgets/pose_painter.dart';
import 'results_screen.dart';

const int _kTargetReps = 5;
const int _kCountdownSeconds = 10;
const _kGetReady = 'Get ready.';
const _kStandInFrame = 'Stand with your full body in frame.';
const _kEndScreen = 'End screen';

class ScreenScreen extends StatefulWidget {
  final String sport;
  final String goal;

  const ScreenScreen({super.key, required this.sport, required this.goal});

  @override
  State<ScreenScreen> createState() => _ScreenScreenState();
}

class _ScreenScreenState extends State<ScreenScreen>
    with SingleTickerProviderStateMixin {
  // I detect simulator at runtime so I can skip camera init and show a placeholder.
  static bool get _isSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  List<Map<PoseLandmarkType, Offset>> _smoothedLandmarks = [];
  bool _isDetecting = false;
  bool _navigated = false;

  bool _countdownActive = true;
  int _countdownValue = _kCountdownSeconds;
  bool _analysisActive = false;
  Timer? _countdownTimer;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayOpacity;

  final _poseDetector = PoseDetector(
    options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
  );
  final _smoother = LandmarkSmoother(windowSize: 5);
  final _analyser = SquatAnalyser();

  @override
  void initState() {
    super.initState();
    _overlayFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );
    _overlayOpacity = CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeOut,
    );
    if (!_isSimulator) _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No cameras found');
        return;
      }
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[0],
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.bgra8888,
      );
      await _controller!.initialize();
      // I start the stream before the countdown ends so the preview is live immediately.
      _controller!.startImageStream(_processFrame);
      if (mounted) {
        setState(() => _isInitialized = true);
        _startCountdown();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdownValue--);
      if (_countdownValue <= 0) {
        timer.cancel();
        _overlayFadeController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _countdownActive = false;
              _analysisActive = true;
            });
          }
        });
      }
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDetecting || _navigated) return;
    _isDetecting = true;
    try {
      final inputImage = _inputImageFromCamera(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }
      final poses = await _poseDetector.processImage(inputImage);
      final smoothedLandmarks =
          poses.map((pose) => _smoother.smooth(pose.landmarks)).toList();

      if (smoothedLandmarks.isNotEmpty && _analysisActive) {
        final imageSize = Size(
          _controller!.value.previewSize!.height,
          _controller!.value.previewSize!.width,
        );
        final newRep =
            _analyser.analyseFrame(smoothedLandmarks.first, imageSize);

        if (newRep && _analyser.repCount >= _kTargetReps && !_navigated) {
          _navigated = true;
          _navigateToResults();
        }
      }

      if (mounted && !_navigated) {
        setState(() => _smoothedLandmarks = smoothedLandmarks);
      }
    } catch (e) {
      print('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCamera(CameraImage image) {
    final camera = _controller!.description;
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _navigateToResults() {
    final faults = _analyser.buildFaultList();
    final score = ScreenResult.calculateScore(faults);
    final result = ScreenResult(
      sport: widget.sport,
      goal: widget.goal,
      repCount: _analyser.repCount,
      faults: faults,
      completedAt: DateTime.now(),
      score: score,
    );
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResultsScreen(result: result)),
      );
    }
  }

  void _endScreenEarly() {
    if (_navigated) return;
    _navigated = true;
    _countdownTimer?.cancel();
    _navigateToResults();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _overlayFadeController.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  String _faultLabel(FaultType type) {
    switch (type) {
      case FaultType.kneeCave:
        return 'Knee cave';
      case FaultType.depth:
        return 'Depth';
      case FaultType.forwardLean:
        return 'Forward lean';
      case FaultType.heelRise:
        return 'Heel rise';
    }
  }

  Widget _buildSimulatorPlaceholder() {
    return Scaffold(
      backgroundColor: PoiseColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_iphone, size: 48, color: PoiseColors.muted),
            const SizedBox(height: 16),
            Text(
              'Simulator',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: PoiseColors.offWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pose detection requires a real device.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: PoiseColors.muted,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Go back',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: PoiseColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isSimulator) return _buildSimulatorPlaceholder();

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: PoiseColors.background,
        body: Center(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.dmSans(color: PoiseColors.error, fontSize: 14),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: PoiseColors.background,
        body: Center(
          child: CircularProgressIndicator(color: PoiseColors.accent),
        ),
      );
    }

    final previewSize = _controller!.value.previewSize!;
    final imageSize = Size(previewSize.height, previewSize.width);
    final repsToGo = (_kTargetReps - _analyser.repCount).clamp(0, _kTargetReps);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview fills the screen.
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(_controller!),
            ),
          ),

          // Skeleton overlay -- only shown once analysis is active.
          if (_analysisActive && _smoothedLandmarks.isNotEmpty)
            CustomPaint(
              painter: PosePainterDelegate(
                smoothedLandmarks: _smoothedLandmarks,
                imageSize: imageSize,
                inSquat: _analyser.inSquat,
                activeFaults: Set.from(_analyser.activeFaults),
              ),
            ),

          // Top gradient to make the UI readable over the camera feed.
          const Positioned(
            top: 0, left: 0, right: 0, height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Bottom gradient.
          const Positioned(
            bottom: 0, left: 0, right: 0, height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // Top-left: live fault pills.
          Positioned(
            top: 56,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: FaultType.values.map((type) {
                final isActive =
                    _analysisActive && _analyser.activeFaults.contains(type);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PoiseColors.card.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: isActive
                          ? const Border(
                              left: BorderSide(
                                  color: PoiseColors.error, width: 2),
                            )
                          : null,
                    ),
                    child: Text(
                      _faultLabel(type),
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            isActive ? PoiseColors.error : PoiseColors.muted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Top-right: sport label.
          Positioned(
            top: 56,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PoiseColors.card.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.sport,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PoiseColors.muted,
                ),
              ),
            ),
          ),

          // Bottom-left: rep counter.
          Positioned(
            bottom: 40,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_analyser.repCount}',
                  style: GoogleFonts.syne(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: PoiseColors.accent,
                    height: 1,
                  ),
                ),
                Text(
                  _analyser.inSquat ? 'Squatting' : 'Standing',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: PoiseColors.offWhite,
                  ),
                ),
                Text(
                  '$repsToGo reps to complete',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: PoiseColors.muted,
                  ),
                ),
              ],
            ),
          ),

          // Bottom-right: early exit.
          Positioned(
            bottom: 44,
            right: 16,
            child: GestureDetector(
              onTap: _endScreenEarly,
              child: Text(
                _kEndScreen,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: PoiseColors.muted,
                ),
              ),
            ),
          ),

          // Countdown overlay -- fades out when the countdown hits zero.
          if (_countdownActive)
            FadeTransition(
              opacity: _overlayOpacity,
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _kGetReady,
                        style: GoogleFonts.syne(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: PoiseColors.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _kStandInFrame,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: PoiseColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '$_countdownValue',
                        style: GoogleFonts.syne(
                          fontSize: 80,
                          fontWeight: FontWeight.w800,
                          color: PoiseColors.accent,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
