// FaultType covers all movements. Not every fault applies to every movement --
// each analyser only emits the faults relevant to its movement.
enum FaultType {
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

enum FaultSeverity { mild, moderate, significant }

class Fault {
  final FaultType type;
  final String name;
  final String description;
  final FaultSeverity severity;
  final int framesDetected;
  // 'left' or 'right' for unilateral movements, null for bilateral.
  final String? side;

  const Fault({
    required this.type,
    required this.name,
    required this.description,
    required this.severity,
    required this.framesDetected,
    this.side,
  });

  static Fault fromType(FaultType type, int framesDetected, {String? side}) {
    final severity = _severityFromFrames(framesDetected);
    final sideLabel = side != null
        ? ' (${side[0].toUpperCase()}${side.substring(1)})'
        : '';
    switch (type) {
      case FaultType.kneeCave:
        return Fault(
          type: type,
          name: 'Knee Cave$sideLabel',
          description:
              'Your knee is collapsing inward, increasing stress on the knee joint.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.depth:
        return Fault(
          type: type,
          name: 'Insufficient Depth',
          description:
              'Your hips are not reaching parallel depth, reducing the effectiveness of the movement.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.forwardLean:
        return Fault(
          type: type,
          name: 'Forward Lean$sideLabel',
          description:
              'Your torso is leaning excessively forward, placing extra load on the lower back.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.heelRise:
        return Fault(
          type: type,
          name: 'Heel Rise$sideLabel',
          description:
              'Your heel is lifting off the ground, indicating limited ankle dorsiflexion.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.hipDrop:
        return Fault(
          type: type,
          name: 'Hip Drop$sideLabel',
          description:
              'Your pelvis is dropping to one side, indicating weak hip abductors (glute med).',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.excessiveSway:
        return Fault(
          type: type,
          name: 'Excessive Sway$sideLabel',
          description:
              'Your body is swaying significantly during the balance hold, indicating limited ankle stability.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.armFallForward:
        return Fault(
          type: type,
          name: 'Arms Falling Forward',
          description:
              'Your arms are dropping forward during the overhead squat, indicating limited shoulder or thoracic mobility.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.limitedRotation:
        return Fault(
          type: type,
          name: 'Limited Overhead Reach$sideLabel',
          description:
              'Your arm is not reaching full overhead position, indicating restricted shoulder flexion or rotation range.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
      case FaultType.excessiveKneeBend:
        return Fault(
          type: type,
          name: 'Excessive Knee Bend',
          description:
              'Your knees are bending too much during the hinge, turning it into a squat pattern. Focus on pushing hips back rather than knees forward.',
          severity: severity,
          framesDetected: framesDetected,
          side: side,
        );
    }
  }

  // Thresholds tuned from POC testing -- 10 frames is about 0.3s at 30fps.
  static FaultSeverity _severityFromFrames(int frames) {
    if (frames <= 10) return FaultSeverity.mild;
    if (frames <= 25) return FaultSeverity.moderate;
    return FaultSeverity.significant;
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'name': name,
      'description': description,
      'severity': severity.name,
      'framesDetected': framesDetected,
      if (side != null) 'side': side,
    };
  }

  factory Fault.fromMap(Map<String, dynamic> map) {
    final type = FaultType.values.firstWhere((e) => e.name == map['type']);
    final severity =
        FaultSeverity.values.firstWhere((e) => e.name == map['severity']);
    return Fault(
      type: type,
      name: map['name'] as String,
      description: map['description'] as String,
      severity: severity,
      framesDetected: map['framesDetected'] as int,
      side: map['side'] as String?,
    );
  }
}
