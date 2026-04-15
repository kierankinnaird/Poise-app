// A fitness plan is a list of exercise suggestions. The model is simple --
// MovementSuggestionsGenerator is responsible for deciding which exercises to suggest.
import 'movement_observation.dart';

class Exercise {
  final String name;
  final String sets;
  final String? duration; // null for rep-based exercises
  final String description;
  final MovementObservationType? targetObservation; // null for general warmup exercises

  const Exercise({
    required this.name,
    required this.sets,
    this.duration,
    required this.description,
    this.targetObservation,
  });
}

class FitnessPlan {
  final List<Exercise> exercises;

  const FitnessPlan({required this.exercises});
}
