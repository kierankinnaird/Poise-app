// Defines all supported movement types and their screen metadata.
// MovementType drives analyser selection in ScreenScreen and display in ResultsScreen.
enum MovementType {
  squat,
  lunge,
  singleLegSquat,
  singleLegStand,
  overheadSquat,
}

extension MovementTypeX on MovementType {
  String get displayName {
    switch (this) {
      case MovementType.squat:
        return 'Squat';
      case MovementType.lunge:
        return 'Lunge';
      case MovementType.singleLegSquat:
        return 'Single Leg Squat';
      case MovementType.singleLegStand:
        return 'Single Leg Stand';
      case MovementType.overheadSquat:
        return 'Overhead Squat';
    }
  }

  // Shown on the screen screen to guide the user.
  String get setupInstruction {
    switch (this) {
      case MovementType.squat:
        return 'Stand with feet shoulder-width apart, toes slightly out.';
      case MovementType.lunge:
        return 'Stand tall. Step forward into a lunge -- 5 reps each leg.';
      case MovementType.singleLegSquat:
        return 'Balance on one leg, arms forward for balance. 5 reps each leg.';
      case MovementType.singleLegStand:
        return 'Balance on one leg, arms at your sides. 15 seconds each leg.';
      case MovementType.overheadSquat:
        return 'Raise both arms fully overhead. Keep them there throughout.';
    }
  }

  // True for lunge, single leg squat, single leg stand -- they do left then right.
  bool get isUnilateral {
    switch (this) {
      case MovementType.lunge:
      case MovementType.singleLegSquat:
      case MovementType.singleLegStand:
        return true;
      case MovementType.squat:
      case MovementType.overheadSquat:
        return false;
    }
  }

  // Single leg stand is timed rather than rep-counted.
  bool get isTimed => this == MovementType.singleLegStand;

  // Target reps per side (or total for bilateral). 0 for timed movements.
  int get targetReps {
    switch (this) {
      case MovementType.singleLegStand:
        return 0;
      default:
        return 5;
    }
  }

  // Hold duration in seconds for timed movements.
  int get holdSeconds => this == MovementType.singleLegStand ? 15 : 0;

  // Used to look up stored results and display movement type in history.
  String get storageKey => name;

  static MovementType fromStorageKey(String key) {
    return MovementType.values.firstWhere(
      (m) => m.name == key,
      orElse: () => MovementType.squat,
    );
  }
}
