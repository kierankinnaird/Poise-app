// The four squat faults I screen for. FaultType drives everything downstream --
// the analyser detects them, the results screen displays them, and the prehab
// generator maps them to corrective exercises.
enum FaultType { kneeCave, depth, forwardLean, heelRise }

enum FaultSeverity { mild, moderate, significant }

class Fault {
  final FaultType type;
  final String name;
  final String description;
  final FaultSeverity severity;
  final int framesDetected;

  const Fault({
    required this.type,
    required this.name,
    required this.description,
    required this.severity,
    required this.framesDetected,
  });

  // I build a Fault from its type and frame count so the analyser doesn't
  // need to know the display strings.
  static Fault fromType(FaultType type, int framesDetected) {
    final severity = _severityFromFrames(framesDetected);
    switch (type) {
      case FaultType.kneeCave:
        return Fault(
          type: type,
          name: 'Knee Cave',
          description:
              'Your knees are collapsing inward during the squat, increasing stress on the knee joint.',
          severity: severity,
          framesDetected: framesDetected,
        );
      case FaultType.depth:
        return Fault(
          type: type,
          name: 'Insufficient Depth',
          description:
              'Your hips are not reaching parallel depth, reducing the effectiveness of the squat.',
          severity: severity,
          framesDetected: framesDetected,
        );
      case FaultType.forwardLean:
        return Fault(
          type: type,
          name: 'Forward Lean',
          description:
              'Your torso is leaning excessively forward, placing extra load on the lower back.',
          severity: severity,
          framesDetected: framesDetected,
        );
      case FaultType.heelRise:
        return Fault(
          type: type,
          name: 'Heel Rise',
          description:
              'Your heels are lifting off the ground, indicating limited ankle dorsiflexion.',
          severity: severity,
          framesDetected: framesDetected,
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
    );
  }
}
