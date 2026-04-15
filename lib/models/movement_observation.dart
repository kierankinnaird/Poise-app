// MovementObservationType covers all movements. Not every observation applies to every movement --
// each analyser only emits the observations relevant to its movement.
// These are movement variations observed during analysis, presented for educational purposes.
enum MovementObservationType {
  // Shared across movements
  kneeCave,
  forwardLean,
  heelRise,
  hipDrop,
  // Squat / overhead squat
  depth,
  // Single leg stand
  excessiveSway,
  // Overhead squat
  armFallForward,
  // Shoulder rotation
  limitedRotation,
  // Hip hinge
  excessiveKneeBend,
}

enum ObservationIntensity { minimal, moderate, significant }

class MovementObservation {
  final MovementObservationType type;
  final String name;
  final String description;
  final ObservationIntensity intensity;
  final int framesDetected;
  // 'left' or 'right' for unilateral movements, null for bilateral.
  final String? side;

  const MovementObservation({
    required this.type,
    required this.name,
    required this.description,
    required this.intensity,
    required this.framesDetected,
    this.side,
  });

  static MovementObservation fromType(MovementObservationType type, int framesDetected, {String? side}) {
    final intensity = _intensityFromFrames(framesDetected);
    final sideLabel = side != null
        ? ' (${side[0].toUpperCase()}${side.substring(1)})'
        : '';
    switch (type) {
      case MovementObservationType.kneeCave:
        return MovementObservation(
          type: type,
          name: 'Knee Inward Pattern$sideLabel',
          description:
              'Knees moving inward during the movement. This is a common variation; exercises like lateral band walks can help explore different movement patterns.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.depth:
        return MovementObservation(
          type: type,
          name: 'Limited Depth Variation',
          description:
              'The movement does not reach maximum depth. Explore deeper ranges gradually with mobility work like hip flexor stretches and deep squats holds.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.forwardLean:
        return MovementObservation(
          type: type,
          name: 'Forward Torso Lean$sideLabel',
          description:
              'Torso leaning forward during movement. Thoracic extension and core engagement exercises like cat-cow mobility can help explore more upright positions.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.heelRise:
        return MovementObservation(
          type: type,
          name: 'Heel Lift Pattern$sideLabel',
          description:
              'Heels lifting off the ground during movement. Ankle mobility drills and calf strengthening exercises explore different ranges.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.hipDrop:
        return MovementObservation(
          type: type,
          name: 'Hip Drop Pattern$sideLabel',
          description:
              'Pelvis dropping to one side during movement. Hip abduction and single-leg stability exercises can help develop different movement patterns.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.excessiveSway:
        return MovementObservation(
          type: type,
          name: 'Sway Pattern$sideLabel',
          description:
              'Significant body sway during balance work. Single-leg balance exercises with eyes closed and ankle stability drills can explore more stable positions.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.armFallForward:
        return MovementObservation(
          type: type,
          name: 'Arms Forward Pattern',
          description:
              'Arms dropping forward during overhead movements. Shoulder mobility work like wall angels and band dislocates explore different arm positions.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.limitedRotation:
        return MovementObservation(
          type: type,
          name: 'Limited Rotation Range$sideLabel',
          description:
              'Restricted range during rotation movement. Shoulder mobility stretches like doorway shoulder stretches help explore greater ranges.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
      case MovementObservationType.excessiveKneeBend:
        return MovementObservation(
          type: type,
          name: 'Knee-Dominant Pattern',
          description:
              'Knees bending prominently during hinge movement. Hip hinge specific work and posterior chain engagement exercises explore hip-focused patterns.',
          intensity: intensity,
          framesDetected: framesDetected,
          side: side,
        );
    }
  }

  // Thresholds tuned from POC testing -- 10 frames is about 0.3s at 30fps.
  static ObservationIntensity _intensityFromFrames(int frames) {
    if (frames <= 10) return ObservationIntensity.minimal;
    if (frames <= 25) return ObservationIntensity.moderate;
    return ObservationIntensity.significant;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'intensity': intensity.name,
      'framesDetected': framesDetected,
      if (side != null) 'side': side,
    };
  }

  factory MovementObservation.fromMap(Map<String, dynamic> map) {
    final type = MovementObservationType.values.firstWhere((e) => e.name == map['type']);
    final intensity =
        ObservationIntensity.values.firstWhere((e) => e.name == map['intensity']);
    return MovementObservation(
      type: type,
      name: map['name'] as String,
      description: map['description'] as String,
      intensity: intensity,
      framesDetected: map['framesDetected'] as int,
      side: map['side'] as String?,
    );
  }
}
