import 'package:doobi/models/quiz_model.dart';
import 'package:doobi/repositories/quiz_repository.dart';
import 'package:doobi/viewmodels/base_viewmodel.dart';

class WordQuizViewModel extends BaseViewModel {
  final QuizRepository _quizRepository;
  List<QuizModel> _quizzes = [];
  int _currentIndex = 0;
  int _score = 0;

  WordQuizViewModel(this._quizRepository);

  List<QuizModel> get quizzes => _quizzes;
  int get currentIndex => _currentIndex;
  int get score => _score;
  QuizModel? get currentQuiz =>
      _quizzes.isNotEmpty ? _quizzes[_currentIndex] : null;

  Future<void> loadQuizzes(String difficulty, int count) async {
    setLoading(true);
    try {
      _quizzes = await _quizRepository.getQuizzes(difficulty, count);
      notifyListeners();
    } catch (e) {
      // 에러 처리
    } finally {
      setLoading(false);
    }
  }

  void submitAnswer(String answer) {
    if (currentQuiz == null) return;

    if (currentQuiz!.correctAnswer == answer) {
      _score++;
    }

    if (_currentIndex < _quizzes.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  bool get isLastQuestion => _currentIndex == _quizzes.length - 1;
}
