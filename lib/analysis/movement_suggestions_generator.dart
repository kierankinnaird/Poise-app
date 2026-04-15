// Maps observed movement patterns to suggested exercises for general fitness.
// This is educational content for fitness exploration and conditioning.
// I cap the plan at 5 exercises total -- enough to be useful without overwhelming the user.
// For multiple observations I take fewer exercises per observation so the total stays manageable.
import '../models/movement_observation.dart';
import '../models/fitness_plan.dart';

class MovementSuggestionsGenerator {
  static const _kneeMovementExercises = [
    Exercise(
      name: 'Banded Clamshells',
      sets: '3 sets x 15 reps',
      description:
          'Lie on side, feet together, rotate top knee open while keeping feet together. Great for hip and glute activation.',
      targetObservation: MovementObservationType.kneeCave,
    ),
    Exercise(
      name: 'Single-leg Glute Bridge',
      sets: '3 sets x 12 reps',
      description:
          'Lie on back, single leg extended, drive hips up through planted foot. Builds single-leg stability.',
      targetObservation: MovementObservationType.kneeCave,
    ),
    Exercise(
      name: 'Lateral Band Walks',
      sets: '3 sets x 10 reps each',
      description:
          'Step sideways against band resistance, keep toes forward and knees soft. Strengthens hip abductors.',
      targetObservation: MovementObservationType.kneeCave,
    ),
  ];

  static const _depthExercises = [
    Exercise(
      name: 'Hip Flexor Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description: 'Lunge position, drive hips forward, keep torso tall. Helpful for exploring mobility.',
      targetObservation: MovementObservationType.depth,
    ),
    Exercise(
      name: 'Deep Squat Hold',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Hold bottom of squat position using support if needed, gradually work toward deeper ranges.',
      targetObservation: MovementObservationType.depth,
    ),
    Exercise(
      name: 'Ankle Dorsiflexion Drill',
      sets: '3 sets x 12 reps',
      description:
          'Knee-to-wall drill: drive knee over little toe to explore ankle mobility.',
      targetObservation: MovementObservationType.depth,
    ),
  ];

  static const _forwardLeanExercises = [
    Exercise(
      name: 'Thoracic Extension over Foam Roller',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Lie over roller at mid-back, arms crossed, let upper back open over roller. Improves thoracic mobility.',
      targetObservation: MovementObservationType.forwardLean,
    ),
    Exercise(
      name: 'Goblet Squat',
      sets: '3 sets x 10 reps',
      description:
          'Hold weight at chest, squat keeping torso upright and elbows inside knees. Good for patterning.',
      targetObservation: MovementObservationType.forwardLean,
    ),
    Exercise(
      name: 'Cat-Cow Mobility',
      sets: '3 sets x 10 reps',
      description:
          'On all fours, alternate between arching and rounding the spine. Explores spinal mobility.',
      targetObservation: MovementObservationType.forwardLean,
    ),
  ];

  static const _heelRiseExercises = [
    Exercise(
      name: 'Ankle Dorsiflexion Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Half-kneeling calf stretch, drive knee forward over toe. Works ankle range of motion.',
      targetObservation: MovementObservationType.heelRise,
    ),
    Exercise(
      name: 'Calf Raise Eccentric',
      sets: '3 sets x 15 reps',
      description:
          'Rise up on both feet, lower slowly on single foot over 3-4 seconds. Develops ankle stability.',
      targetObservation: MovementObservationType.heelRise,
    ),
    Exercise(
      name: 'Elevated Heel Squat',
      sets: '3 sets x 10 reps',
      description:
          'Heels raised on plates, focus on keeping weight distributed through the foot.',
      targetObservation: MovementObservationType.heelRise,
    ),
  ];

  static const _hipDropExercises = [
    Exercise(
      name: 'Side-lying Hip Abduction',
      sets: '3 sets x 15 reps',
      description:
          'Lie on side, keep hips stacked, raise top leg to 45 degrees and lower slowly. Targets hip stability.',
      targetObservation: MovementObservationType.hipDrop,
    ),
    Exercise(
      name: 'Single-leg Deadlift',
      sets: '3 sets x 8 reps each',
      description:
          'Balance on one leg, hinge forward keeping hips level, return to standing. Improves single-leg control.',
      targetObservation: MovementObservationType.hipDrop,
    ),
    Exercise(
      name: 'Lateral Band Walk',
      sets: '3 sets x 12 reps each',
      description:
          'Band around thighs, step sideways keeping pelvis level and knees soft. Strengthens hip abductors.',
      targetObservation: MovementObservationType.hipDrop,
    ),
  ];

  static const _excessiveSwayExercises = [
    Exercise(
      name: 'Single-leg Balance with Eyes Closed',
      sets: '3 sets',
      duration: '20 sec hold',
      description:
          'Stand on one leg, arms at sides, close eyes to challenge proprioception. Improves balance.',
      targetObservation: MovementObservationType.excessiveSway,
    ),
    Exercise(
      name: 'Ankle Alphabet',
      sets: '2 sets each ankle',
      description:
          'Seated or lying, trace the alphabet with your foot to improve ankle mobility and control.',
      targetObservation: MovementObservationType.excessiveSway,
    ),
    Exercise(
      name: 'Calf Raise Balance',
      sets: '3 sets x 12 reps',
      description:
          'Stand on one leg, rise onto toes slowly and lower with control. Develops ankle stability.',
      targetObservation: MovementObservationType.excessiveSway,
    ),
  ];

  static const _armFallForwardExercises = [
    Exercise(
      name: 'Wall Angel',
      sets: '3 sets x 10 reps',
      description:
          'Back against wall, slide arms overhead keeping wrists and elbows in contact with wall. Improves shoulder mobility.',
      targetObservation: MovementObservationType.armFallForward,
    ),
    Exercise(
      name: 'Shoulder Dislocates with Band',
      sets: '3 sets x 10 reps',
      description:
          'Hold band wide with straight arms, rotate overhead and behind in a controlled arc. Explores shoulder range.',
      targetObservation: MovementObservationType.armFallForward,
    ),
    Exercise(
      name: 'Thoracic Rotation Stretch',
      sets: '3 sets x 5 reps each',
      duration: '5 sec hold',
      description:
          'Seated or kneeling, rotate upper back through full range, hands behind head. Opens up thoracic rotation.',
      targetObservation: MovementObservationType.armFallForward,
    ),
  ];

  static const _limitedRotationExercises = [
    Exercise(
      name: 'Doorway Shoulder Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Place forearm on door frame at 90 degrees, rotate body away to open the chest and stretch the shoulder.',
      targetObservation: MovementObservationType.limitedRotation,
    ),
    Exercise(
      name: 'Sleeper Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Lie on side with arm out at shoulder height, use other hand to gently rotate forearm toward the floor. Great shoulder opener.',
      targetObservation: MovementObservationType.limitedRotation,
    ),
    Exercise(
      name: 'Band External Rotation',
      sets: '3 sets x 15 reps',
      description:
          'Anchor band at elbow height, elbow at 90 degrees by side, rotate forearm outward against resistance. Strengthens rotator cuff.',
      targetObservation: MovementObservationType.limitedRotation,
    ),
  ];

  static const _excessiveKneeBendExercises = [
    Exercise(
      name: 'Romanian Deadlift',
      sets: '3 sets x 10 reps',
      description:
          'Hold dumbbells at thighs, push hips back and lower weights down legs with soft knees. Emphasizes hip hinge pattern.',
      targetObservation: MovementObservationType.excessiveKneeBend,
    ),
    Exercise(
      name: 'Hip Hinge Wall Drill',
      sets: '3 sets x 10 reps',
      description:
          'Stand 30cm from wall, push hips back to touch the wall without bending knees excessively. Helps pattern hip-dominant movement.',
      targetObservation: MovementObservationType.excessiveKneeBend,
    ),
    Exercise(
      name: 'Hamstring Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Seated or lying, extend one leg and flex the foot, reaching toward toes to stretch the hamstring.',
      targetObservation: MovementObservationType.excessiveKneeBend,
    ),
  ];

  static const _warmupExercise = Exercise(
    name: 'Squat Warmup Flow',
    sets: '1 set',
    description:
        'Bodyweight squat x10, deep squat hold x30s, hip circle x10 each side. Good general warm-up.',
    targetObservation: null,
  );

  static FitnessPlan generate(List<MovementObservation> observations) {
    // No observations detected -- I still give a warmup so the user has something to do.
    if (observations.isEmpty) {
      return const FitnessPlan(exercises: [_warmupExercise]);
    }

    final exercises = <Exercise>[];
    final observationTypes = observations.map((o) => o.type).toSet();

    const exerciseMap = {
      MovementObservationType.kneeCave: _kneeMovementExercises,
      MovementObservationType.depth: _depthExercises,
      MovementObservationType.forwardLean: _forwardLeanExercises,
      MovementObservationType.heelRise: _heelRiseExercises,
      MovementObservationType.hipDrop: _hipDropExercises,
      MovementObservationType.excessiveSway: _excessiveSwayExercises,
      MovementObservationType.armFallForward: _armFallForwardExercises,
      MovementObservationType.limitedRotation: _limitedRotationExercises,
      MovementObservationType.excessiveKneeBend: _excessiveKneeBendExercises,
    };

    // With more than 2 observations I take 1 exercise each, otherwise 2 each.
    final exercisesPerObservation = observationTypes.length > 2 ? 1 : 2;

    for (final type in observationTypes) {
      final pool = exerciseMap[type];
      if (pool == null) continue;
      exercises.addAll(pool.take(exercisesPerObservation.clamp(0, pool.length)));
      if (exercises.length >= 5) break;
    }

    return FitnessPlan(exercises: exercises.take(5).toList());
  }
}
