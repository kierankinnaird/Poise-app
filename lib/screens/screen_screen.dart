// ignore_for_file: avoid_print
// The live camera screen. Runs all 5 movements in sequence -- squat, lunge,
// hip hinge, single leg stand, shoulder rotation. Between movements a
// transition overlay prompts the user to get ready for the next one.
// On simulator I show a placeholder because MLKit requires a real device.
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../analysis/landmark_smoother.dart';
import '../analysis/hip_hinge_analyser.dart';
import '../analysis/lunge_analyser.dart';
import '../analysis/shoulder_rotation_analyser.dart';
import '../analysis/single_leg_stand_analyser.dart';
import '../analysis/squat_analyser.dart';
import '../models/fault.dart';
import '../models/movement_type.dart';
import '../models/screen_result.dart';
import '../theme/app_theme.dart';
import '../widgets/pose_painter.dart';
import 'results_screen.dart';

const int _kTargetReps = 5;
const int _kCountdownSeconds = 10;
const int _kTransitionCountdownSeconds = 5;
const _kGetReady = 'Get ready.';
const _kEndScreen = 'End screen';
const _kMovementComplete = 'Movement complete';
const _kUpNext = 'Up next';
const _kReady = 'I\'m ready';

const _kAllMovements = [
  MovementType.squat,
  MovementType.lunge,
  MovementType.hipHinge,
  MovementType.singleLegStand,
  MovementType.shoulderRotation,
];

class ScreenScreen extends StatefulWidget {
  final String sport;
  final String goal;

  const ScreenScreen({
    super.key,
    required this.sport,
    required this.goal,
  });

  @override
  State<ScreenScreen> createState() => _ScreenScreenState();
}

class _ScreenScreenState extends State<ScreenScreen>
    with SingleTickerProviderStateMixin {
  static bool get _isSimulator =>
      Platform.isIOS &&
      Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  List<Map<PoseLandmarkType, Offset>> _smoothedLandmarks = [];
  bool _isDetecting = false;

  // Movement sequencing
  int _currentMovementIndex = 0;
  final List<Fault> _allFaults = [];
  bool _showingTransition = false;
  int _transitionCountdown = _kTransitionCountdownSeconds;
  Timer? _transitionTimer;

  // Per-movement countdown
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

  SquatAnalyser? _squatAnalyser;
  LungeAnalyser? _lungeAnalyser;
  SingleLegStandAnalyser? _singleLegStandAnalyser;
  ShoulderRotationAnalyser? _shoulderRotationAnalyser;
  HipHingeAnalyser? _hipHingeAnalyser;

  // Timed movement state (single leg stand).
  Timer? _holdTimer;
  int _holdSecondsRemaining = 15;
  bool _holdTimerActive = false;

  MovementType get _currentMovement => _kAllMovements[_currentMovementIndex];
  bool get _isLastMovement => _currentMovementIndex == _kAllMovements.length - 1;

  int get _currentReps {
    if (_squatAnalyser != null) return _squatAnalyser!.repCount;
    if (_lungeAnalyser != null) return _lungeAnalyser!.activeRepCount;
    if (_shoulderRotationAnalyser != null) return _shoulderRotationAnalyser!.activeRepCount;
    if (_hipHingeAnalyser != null) return _hipHingeAnalyser!.repCount;
    return 0;
  }

  bool get _inMovement {
    if (_squatAnalyser != null) return _squatAnalyser!.inSquat;
    if (_lungeAnalyser != null) return _lungeAnalyser!.inLunge;
    if (_singleLegStandAnalyser != null) return _singleLegStandAnalyser!.inStance;
    if (_shoulderRotationAnalyser != null) return _shoulderRotationAnalyser!.inRaise;
    if (_hipHingeAnalyser != null) return _hipHingeAnalyser!.inHinge;
    return false;
  }

  Set<FaultType> get _activeFaults {
    if (_squatAnalyser != null) return _squatAnalyser!.activeFaults;
    if (_lungeAnalyser != null) return _lungeAnalyser!.activeFaults;
    if (_singleLegStandAnalyser != null) return _singleLegStandAnalyser!.activeFaults;
    if (_shoulderRotationAnalyser != null) return _shoulderRotationAnalyser!.activeFaults;
    if (_hipHingeAnalyser != null) return _hipHingeAnalyser!.activeFaults;
    return {};
  }

  String? get _activeSide {
    if (_lungeAnalyser != null) return _lungeAnalyser!.activeSide;
    if (_singleLegStandAnalyser != null) return _singleLegStandAnalyser!.activeSide;
    if (_shoulderRotationAnalyser != null) return _shoulderRotationAnalyser!.activeSide;
    return null;
  }

  List<Fault> _buildFaultList() {
    if (_squatAnalyser != null) return _squatAnalyser!.buildFaultList();
    if (_lungeAnalyser != null) return _lungeAnalyser!.buildFaultList();
    if (_singleLegStandAnalyser != null) return _singleLegStandAnalyser!.buildFaultList();
    if (_shoulderRotationAnalyser != null) return _shoulderRotationAnalyser!.buildFaultList();
    if (_hipHingeAnalyser != null) return _hipHingeAnalyser!.buildFaultList();
    return [];
  }

  List<FaultType> get _relevantFaults {
    switch (_currentMovement) {
      case MovementType.lunge:
        return [FaultType.kneeCave, FaultType.hipDrop, FaultType.forwardLean, FaultType.heelRise];
      case MovementType.singleLegStand:
        return [FaultType.excessiveSway];
      case MovementType.hipHinge:
        return [FaultType.excessiveKneeBend, FaultType.kneeCave, FaultType.heelRise];
      case MovementType.shoulderRotation:
        return [FaultType.limitedRotation];
      default:
        return [FaultType.kneeCave, FaultType.depth, FaultType.forwardLean, FaultType.heelRise];
    }
  }

  String get _movementStatusLabel {
    if (_currentMovement.isTimed) {
      return _holdTimerActive ? 'Balancing' : 'Lift your foot';
    }
    if (!_inMovement) {
      return _currentMovement == MovementType.shoulderRotation ? 'At rest' : 'Standing';
    }
    switch (_currentMovement) {
      case MovementType.lunge: return 'Lunging';
      case MovementType.hipHinge: return 'Hinging';
      case MovementType.shoulderRotation: return 'Raising';
      default: return 'Squatting';
    }
  }

  String get _mainDisplayValue {
    if (_currentMovement.isTimed) return '$_holdSecondsRemaining';
    return '$_currentReps';
  }

  String get _mainDisplaySublabel {
    if (_currentMovement.isTimed) {
      return _holdTimerActive ? 'sec remaining' : 'sec hold';
    }
    return _movementStatusLabel;
  }

  @override
  void initState() {
    super.initState();
    _initAnalyser(_currentMovement);
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

  void _initAnalyser(MovementType movement) {
    _squatAnalyser = null;
    _lungeAnalyser = null;
    _singleLegStandAnalyser = null;
    _shoulderRotationAnalyser = null;
    _hipHingeAnalyser = null;

    switch (movement) {
      case MovementType.lunge:
        _lungeAnalyser = LungeAnalyser();
      case MovementType.singleLegStand:
        _singleLegStandAnalyser = SingleLegStandAnalyser();
        _holdSecondsRemaining = movement.holdSeconds;
        _holdTimerActive = false;
      case MovementType.shoulderRotation:
        _shoulderRotationAnalyser = ShoulderRotationAnalyser();
      case MovementType.hipHinge:
        _hipHingeAnalyser = HipHingeAnalyser();
      default:
        _squatAnalyser = SquatAnalyser();
    }
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
    setState(() {
      _countdownActive = true;
      _countdownValue = _kCountdownSeconds;
      _analysisActive = false;
    });
    _overlayFadeController.value = 1.0;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
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
    if (_isDetecting || _showingTransition || !_analysisActive) return;
    _isDetecting = true;
    try {
      final inputImage = _inputImageFromCamera(image);
      if (inputImage == null) { _isDetecting = false; return; }
      final poses = await _poseDetector.processImage(inputImage);
      final smoothedLandmarks =
          poses.map((pose) => _smoother.smooth(pose.landmarks)).toList();

      if (smoothedLandmarks.isNotEmpty && _analysisActive) {
        final imageSize = Size(
          _controller!.value.previewSize!.height,
          _controller!.value.previewSize!.width,
        );
        _processAnalysis(smoothedLandmarks.first, imageSize);
      }

      if (mounted) setState(() => _smoothedLandmarks = smoothedLandmarks);
    } catch (e) {
      print('Detection error: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _processAnalysis(Map<PoseLandmarkType, Offset> landmarks, Size imageSize) {
    if (_showingTransition) return;
    if (_squatAnalyser != null) {
      final newRep = _squatAnalyser!.analyseFrame(landmarks, imageSize);
      if (newRep && _squatAnalyser!.repCount >= _kTargetReps) _onMovementComplete();
    } else if (_lungeAnalyser != null) {
      _handleUnilateralRep(
        newRep: _lungeAnalyser!.analyseFrame(landmarks, imageSize),
        activeSide: _lungeAnalyser!.activeSide,
        leftReps: _lungeAnalyser!.leftRepCount,
        rightReps: _lungeAnalyser!.rightRepCount,
        switchSide: _lungeAnalyser!.switchSide,
      );
    } else if (_shoulderRotationAnalyser != null) {
      _handleUnilateralRep(
        newRep: _shoulderRotationAnalyser!.analyseFrame(landmarks, imageSize),
        activeSide: _shoulderRotationAnalyser!.activeSide,
        leftReps: _shoulderRotationAnalyser!.leftRepCount,
        rightReps: _shoulderRotationAnalyser!.rightRepCount,
        switchSide: _shoulderRotationAnalyser!.switchSide,
      );
    } else if (_hipHingeAnalyser != null) {
      final newRep = _hipHingeAnalyser!.analyseFrame(landmarks, imageSize);
      if (newRep && _hipHingeAnalyser!.repCount >= _kTargetReps) _onMovementComplete();
    } else if (_singleLegStandAnalyser != null) {
      final inStance = _singleLegStandAnalyser!.analyseFrame(landmarks, imageSize);
      if (inStance && !_holdTimerActive) {
        _startHoldTimer();
      } else if (!inStance && _holdTimerActive) {
        _cancelHoldTimer();
      }
    }
  }

  void _handleUnilateralRep({
    required bool newRep,
    required String activeSide,
    required int leftReps,
    required int rightReps,
    required VoidCallback switchSide,
  }) {
    if (!newRep || _showingTransition) return;
    final sideReps = activeSide == 'left' ? leftReps : rightReps;
    if (activeSide == 'left' && sideReps >= _kTargetReps) {
      switchSide();
      if (mounted) setState(() {});
    } else if (activeSide == 'right' && sideReps >= _kTargetReps) {
      _onMovementComplete();
    }
  }

  void _startHoldTimer() {
    _holdTimerActive = true;
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _holdSecondsRemaining--);
      if (_holdSecondsRemaining <= 0) {
        timer.cancel();
        _holdTimerActive = false;
        if (_singleLegStandAnalyser!.activeSide == 'left') {
          _singleLegStandAnalyser!.switchSide();
          setState(() => _holdSecondsRemaining = _currentMovement.holdSeconds);
        } else {
          _onMovementComplete();
        }
      }
    });
  }

  void _cancelHoldTimer() {
    _holdTimer?.cancel();
    _holdTimerActive = false;
    if (mounted) setState(() => _holdSecondsRemaining = _currentMovement.holdSeconds);
  }

  void _onMovementComplete() {
    if (_showingTransition) return;
    _allFaults.addAll(_buildFaultList());
    _analysisActive = false;
    _countdownTimer?.cancel();
    _holdTimer?.cancel();

    if (_isLastMovement) {
      _navigateToResults();
    } else {
      setState(() {
        _showingTransition = true;
        _transitionCountdown = _kTransitionCountdownSeconds;
      });
      _startTransitionCountdown();
    }
  }

  void _startTransitionCountdown() {
    _transitionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _transitionCountdown--);
      if (_transitionCountdown <= 0) {
        timer.cancel();
        _advanceToNextMovement();
      }
    });
  }

  void _advanceToNextMovement() {
    _transitionTimer?.cancel();
    setState(() {
      _currentMovementIndex++;
      _showingTransition = false;
    });
    _initAnalyser(_currentMovement);
    _smoother.reset();
    _startCountdown();
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
    // Guard: if no reps were completed in any movement, the screen has no valid
    // data. A completed prior movement sets _currentMovementIndex > 0 or adds
    // to _allFaults. _currentReps > 0 means reps were done in the current movement.
    final hasData =
        _currentMovementIndex > 0 || _currentReps > 0 || _allFaults.isNotEmpty;
    if (!hasData) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: PoiseColors.card,
            title: Text(
              'No exercises completed',
              style: GoogleFonts.syne(
                color: PoiseColors.offWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              'Complete at least one movement to save your results.',
              style: GoogleFonts.dmSans(
                  color: PoiseColors.muted, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // exit screen
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.dmSans(color: PoiseColors.accent),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    final score = ScreenResult.calculateScore(_allFaults);
    final result = ScreenResult(
      sport: widget.sport,
      goal: widget.goal,
      movementType: MovementType.fullScreen,
      repCount: 0,
      faults: _allFaults,
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
    if (_showingTransition) return;
    _countdownTimer?.cancel();
    _holdTimer?.cancel();
    _transitionTimer?.cancel();
    _allFaults.addAll(_buildFaultList());
    _navigateToResults();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _holdTimer?.cancel();
    _transitionTimer?.cancel();
    _overlayFadeController.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  String _faultLabel(FaultType type) {
    switch (type) {
      case FaultType.kneeCave: return 'Knee cave';
      case FaultType.depth: return 'Depth';
      case FaultType.forwardLean: return 'Forward lean';
      case FaultType.heelRise: return 'Heel rise';
      case FaultType.hipDrop: return 'Hip drop';
      case FaultType.excessiveSway: return 'Excessive sway';
      case FaultType.armFallForward: return 'Arms falling';
      case FaultType.limitedRotation: return 'Limited reach';
      case FaultType.excessiveKneeBend: return 'Knee bend';
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
              style: GoogleFonts.dmSans(fontSize: 14, color: PoiseColors.muted),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'Go back',
                style: GoogleFonts.dmSans(fontSize: 14, color: PoiseColors.accent),
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
        body: Center(child: CircularProgressIndicator(color: PoiseColors.accent)),
      );
    }

    final previewSize = _controller!.value.previewSize!;
    final imageSize = Size(previewSize.height, previewSize.width);
    final repsToGo = (_kTargetReps - _currentReps).clamp(0, _kTargetReps);
    final side = _activeSide;
    final movementNumber = _currentMovementIndex + 1;

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

          // Skeleton overlay -- only shown during analysis.
          if (_analysisActive && _smoothedLandmarks.isNotEmpty)
            CustomPaint(
              painter: PosePainterDelegate(
                smoothedLandmarks: _smoothedLandmarks,
                imageSize: imageSize,
                inSquat: _inMovement,
                activeFaults: Set.from(_activeFaults),
              ),
            ),

          // Top gradient.
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
          if (!_showingTransition)
            Positioned(
              top: 56,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _relevantFaults.map((type) {
                  final isActive = _analysisActive && _activeFaults.contains(type);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: PoiseColors.card.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: isActive
                            ? const Border(left: BorderSide(color: PoiseColors.error, width: 2))
                            : null,
                      ),
                      child: Text(
                        _faultLabel(type),
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isActive ? PoiseColors.error : PoiseColors.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Top-right: movement progress label.
          if (!_showingTransition)
            Positioned(
              top: 56,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PoiseColors.card.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$movementNumber / ${_kAllMovements.length}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: PoiseColors.muted),
                ),
              ),
            ),

          // Bottom-left: rep counter / hold timer.
          if (!_showingTransition)
            Positioned(
              bottom: 40,
              left: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mainDisplayValue,
                    style: GoogleFonts.syne(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: PoiseColors.accent,
                      height: 1,
                    ),
                  ),
                  Text(
                    _mainDisplaySublabel,
                    style: GoogleFonts.dmSans(fontSize: 12, color: PoiseColors.offWhite),
                  ),
                  if (side != null)
                    Text(
                      _currentMovement == MovementType.shoulderRotation
                          ? '${side.toUpperCase()} ARM'
                          : '${side.toUpperCase()} LEG',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PoiseColors.accent,
                      ),
                    ),
                  if (!_currentMovement.isTimed)
                    Text(
                      '$repsToGo reps to complete',
                      style: GoogleFonts.dmSans(fontSize: 11, color: PoiseColors.muted),
                    ),
                ],
              ),
            ),

          // Bottom-right: early exit.
          if (!_showingTransition)
            Positioned(
              bottom: 44,
              right: 16,
              child: GestureDetector(
                onTap: _endScreenEarly,
                child: Text(
                  _kEndScreen,
                  style: GoogleFonts.dmSans(fontSize: 12, color: PoiseColors.muted),
                ),
              ),
            ),

          // Countdown overlay (fades out when hits zero).
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
                        _currentMovement.setupInstruction,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: PoiseColors.offWhite,
                        ),
                        textAlign: TextAlign.center,
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

          // Between-movement transition overlay.
          if (_showingTransition)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _kMovementComplete,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: PoiseColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _kUpNext,
                        style: GoogleFonts.syne(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PoiseColors.offWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _kAllMovements[_currentMovementIndex + 1].displayName,
                        style: GoogleFonts.syne(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: PoiseColors.accent,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _kAllMovements[_currentMovementIndex + 1].setupInstruction,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: PoiseColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      // Auto-advances after countdown, but user can tap early.
                      GestureDetector(
                        onTap: _advanceToNextMovement,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            color: PoiseColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$_kReady ($_transitionCountdown)',
                            style: GoogleFonts.syne(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
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
