class QuizModel {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String difficulty;

  QuizModel({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
  });
}
