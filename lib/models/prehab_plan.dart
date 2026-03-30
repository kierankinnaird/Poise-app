// A prehab plan is just a list of exercises. I keep the model simple --
// PrehabGenerator is responsible for deciding which exercises go in it.
import 'fault.dart';

class Exercise {
  final String name;
  final String sets;
  final String? duration; // null for rep-based exercises
  final String description;
  final FaultType? targetFault; // null for general warmup exercises

  const Exercise({
    required this.name,
    required this.sets,
    this.duration,
    required this.description,
    this.targetFault,
  });
}

class PrehabPlan {
  final List<Exercise> exercises;

  const PrehabPlan({required this.exercises});
}
