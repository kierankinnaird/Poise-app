// Maps detected faults to a corrective exercise plan.
// I cap the plan at 5 exercises total -- enough to be useful without overwhelming the user.
// For multiple faults I take fewer exercises per fault so the total stays manageable.
import '../models/fault.dart';
import '../models/prehab_plan.dart';

class PrehabGenerator {
  static const _kneeCaveExercises = [
    Exercise(
      name: 'Banded Clamshells',
      sets: '3 sets x 15 reps',
      description:
          'Lie on side, feet together, rotate top knee open while keeping feet together.',
      targetFault: FaultType.kneeCave,
    ),
    Exercise(
      name: 'Single-leg Glute Bridge',
      sets: '3 sets x 12 reps',
      description:
          'Lie on back, single leg extended, drive hips up through planted foot.',
      targetFault: FaultType.kneeCave,
    ),
    Exercise(
      name: 'Lateral Band Walks',
      sets: '3 sets x 10 reps each',
      description:
          'Step sideways against band resistance, keep toes forward and knees soft.',
      targetFault: FaultType.kneeCave,
    ),
  ];

  static const _depthExercises = [
    Exercise(
      name: 'Hip Flexor Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description: 'Lunge position, drive hips forward, keep torso tall.',
      targetFault: FaultType.depth,
    ),
    Exercise(
      name: 'Deep Squat Hold',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Hold bottom of squat position using support if needed, focus on relaxing into depth.',
      targetFault: FaultType.depth,
    ),
    Exercise(
      name: 'Ankle Dorsiflexion Drill',
      sets: '3 sets x 12 reps',
      description:
          'Knee-to-wall drill -- drive knee over little toe without heel lifting.',
      targetFault: FaultType.depth,
    ),
  ];

  static const _forwardLeanExercises = [
    Exercise(
      name: 'Thoracic Extension over Foam Roller',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Lie over roller at mid-back, arms crossed, let upper back open over roller.',
      targetFault: FaultType.forwardLean,
    ),
    Exercise(
      name: 'Goblet Squat',
      sets: '3 sets x 10 reps',
      description:
          'Hold weight at chest, squat keeping torso upright and elbows inside knees.',
      targetFault: FaultType.forwardLean,
    ),
    Exercise(
      name: 'Cat-Cow Mobility',
      sets: '3 sets x 10 reps',
      description:
          'On all fours, alternate between arching and rounding the spine.',
      targetFault: FaultType.forwardLean,
    ),
  ];

  static const _heelRiseExercises = [
    Exercise(
      name: 'Ankle Dorsiflexion Stretch',
      sets: '3 sets',
      duration: '30 sec hold',
      description:
          'Half-kneeling calf stretch, drive knee forward over toe without heel rising.',
      targetFault: FaultType.heelRise,
    ),
    Exercise(
      name: 'Calf Raise Eccentric',
      sets: '3 sets x 15 reps',
      description:
          'Rise up on both feet, lower slowly on single foot over 3-4 seconds.',
      targetFault: FaultType.heelRise,
    ),
    Exercise(
      name: 'Elevated Heel Squat',
      sets: '3 sets x 10 reps',
      description:
          'Heels raised on plates, focus on keeping weight through whole foot as heels lower.',
      targetFault: FaultType.heelRise,
    ),
  ];

  static const _warmupExercise = Exercise(
    name: 'Squat Warmup Flow',
    sets: '1 set',
    description:
        'Bodyweight squat x10, deep squat hold x30s, hip circle x10 each side.',
    targetFault: null,
  );

  static PrehabPlan generate(List<Fault> faults) {
    // No faults detected -- I still give a warmup so the user has something to do.
    if (faults.isEmpty) {
      return const PrehabPlan(exercises: [_warmupExercise]);
    }

    final exercises = <Exercise>[];
    final faultTypes = faults.map((f) => f.type).toSet();

    const exerciseMap = {
      FaultType.kneeCave: _kneeCaveExercises,
      FaultType.depth: _depthExercises,
      FaultType.forwardLean: _forwardLeanExercises,
      FaultType.heelRise: _heelRiseExercises,
    };

    // With more than 2 faults I take 1 exercise each, otherwise 2 each.
    final exercisesPerFault = faultTypes.length > 2 ? 1 : 2;

    for (final type in faultTypes) {
      final pool = exerciseMap[type]!;
      exercises.addAll(pool.take(exercisesPerFault.clamp(0, pool.length)));
      if (exercises.length >= 5) break;
    }

    return PrehabPlan(exercises: exercises.take(5).toList());
  }
}
