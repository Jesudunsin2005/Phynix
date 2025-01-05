import 'package:flutter/material.dart';
import 'package:phynix/root/dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Add this import for Timer

// ignore: constant_identifier_names
const QUIZPOINT = 2;

// Keep existing QuizQuestion class unchanged
class QuizQuestion {
  final String question;
  final Map<String, dynamic> options;
  final String correctAnswer;
  final String? imageUrl;
  final String? explanation;
  int? selectedAnswer;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.imageUrl,
    this.explanation,
    this.selectedAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> options;
    if (json['option'] != null) {
      options = Map<String, dynamic>.from(json['option']);
    } else if (json['options'] != null) {
      options = Map<String, dynamic>.from(json['options']);
    } else {
      options = {};
    }

    return QuizQuestion(
      question: json['question'] ?? '',
      options: options,
      correctAnswer: json['answer'] ?? '',
      imageUrl: json['image'],
      explanation: json['solution'],
      selectedAnswer: json['selectedAnswer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'answer': correctAnswer,
      'image': imageUrl,
      'solution': explanation,
      'selectedAnswer': selectedAnswer,
    };
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> {
  bool _isLoading = true;
  bool _difficultySelected = false;
  String? _selectedDifficulty;
  String? _activeQuizId;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _hasAnswered = false;
  bool _mounted = true;
  bool _showResults = false;
  List<QuizQuestion> questions = [];
  Timer? _timer;
  int _timeRemaining = 0;
  bool _showAnswer = false;
  bool _canChangeAnswer = false;
  Timer? _loadingtimer;
  final List<String> _loadingMessages = [
    "Setting Up...",
    "Fetching Questions...",
    "Almost there...",
    "Preparing your quiz...",
    "Just a moment...",
    "Please wait a moment...",
    "Loading your quiz...",
    "Almost ready...",
    "Crunching the numbers...",
    "Gathering everything...",
    "Hang tight, we're almost done...",
    "Loading... Please stand by...",
    "We are preparing something great for you...",
    "Working on it... Please wait...",
  ];

  int _currentMessageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start timer to update messages
    _loadingtimer = Timer.periodic(const Duration(seconds: 5), (loadingtimer) {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _loadingMessages.length;
      });
    });
    _checkExistingQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loadingtimer?.cancel();
    _mounted = false;
    super.dispose();
  }

  void _startTimer(String difficulty) {
    _timer?.cancel();
    _timeRemaining = difficulty == 'advanced' ? 1800 : 3600; // 30 or 60 minutes
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        safeSetState(() {
          _timeRemaining--;
        });
      } else {
        timer.cancel();
        _completeQuiz();
      }
    });
  }

  String get formattedTime {
    int minutes = _timeRemaining ~/ 60;
    int seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Add this method to check if quiz can be ended early
  bool canEndQuizEarly() {
    return _currentQuestionIndex >= (questions.length * 0.5).floor();
  }

  void _handleAnswerSelection(int index) {
    // Remove the check for _hasAnswered since we want to allow changes
    if (_selectedDifficulty != 'advanced' || !_hasAnswered) {
      safeSetState(() {
        // If changing answer, subtract previous score if it was correct
        if (_hasAnswered) {
          String previousAnswer = String.fromCharCode(
              65 + questions[_currentQuestionIndex].selectedAnswer!);
          if (previousAnswer.toLowerCase() ==
              questions[_currentQuestionIndex].correctAnswer.toLowerCase()) {
            _score -= QUIZPOINT;
          }
        }

        questions[_currentQuestionIndex].selectedAnswer = index;
        _hasAnswered = true;
        _showAnswer = _selectedDifficulty == 'advanced';

        // Add score for new answer if correct
        String selectedOptionLetter = String.fromCharCode(65 + index);
        if (selectedOptionLetter.toLowerCase() ==
            questions[_currentQuestionIndex].correctAnswer.toLowerCase()) {
          _score += QUIZPOINT;
        }
      });
      _updateQuizProgress(_currentQuestionIndex + 1, _score);
    }
  }

  // Add method to handle early quiz completion
  Future<void> _showEndQuizEarlyDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End Quiz Early?'),
          content: const Text(
              'You\'ve completed more than 50% of the quiz. Would you like to end it now?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Continue Quiz'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('End Quiz'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _completeQuiz();
    }
  }

  Future<void> _createNewQuiz(String difficulty) async {
    safeSetState(() {
      _isLoading = true;
    });

    try {
      final fetchedQuestions = await fetchQuestions();
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final questionsJson =
            jsonEncode(fetchedQuestions.map((q) => q.toJson()).toList());

        final response = await supabase.from('quiz_sessions').insert({
          'user_id': user.id,
          'difficulty': difficulty,
          'current_question': 1,
          'total_questions': fetchedQuestions.length,
          'score': 0,
          'completed': false,
          'questions': questionsJson,
        }).select();

        if (response.isNotEmpty && mounted) {
          safeSetState(() {
            questions = fetchedQuestions;
            _activeQuizId = response[0]['id'];
            _difficultySelected = true;
            _selectedDifficulty = difficulty;
            _currentQuestionIndex = 0;
            _score = 0;
            _hasAnswered = false;
            _showResults = false;
            _canChangeAnswer = difficulty != 'advanced';
          });

          if (difficulty != 'beginner') {
            _startTimer(difficulty);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating quiz: $e')),
        );
      }
    } finally {
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  void safeSetState(VoidCallback fn) {
    if (_mounted) {
      setState(fn);
    }
  }

  Future<List<QuizQuestion>> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://questions.aloc.com.ng/api/v2/m/5?subject=physics&random=true&withComprehension=true'),
        headers: {
          'AccessToken': 'ALOC-fe1a9e2acf0e9b7507c4',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final questionsList = (jsonResponse['data'] as List)
            .map((item) => QuizQuestion.fromJson(item))
            .toList();
        return questionsList;
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  Future<void> _checkExistingQuiz() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('quiz_sessions')
            .select()
            .eq('user_id', user.id)
            .eq('completed', false)
            .limit(1)
            .maybeSingle();

        safeSetState(() {
          _isLoading = false;
          if (response != null) {
            _activeQuizId = response['id'];
            _selectedDifficulty = response['difficulty'];
            _currentQuestionIndex = response['current_question'] - 1;
            _score = response['score'];
            _difficultySelected = true;

            final questionsJson = response['questions'];
            if (questionsJson != null) {
              questions = (jsonDecode(questionsJson) as List)
                  .map((q) => QuizQuestion.fromJson(q))
                  .toList();
            }
          }
        });

        if (response != null && mounted) {
          _showContinueQuizDialog();
        }
      }
    } catch (e) {
      safeSetState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking existing quiz: $e')),
        );
      }
    }
  }

  Future<void> _showContinueQuizDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Continue Previous Quiz?'),
          content: const Text(
              'You have an unfinished quiz. Would you like to continue?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Start New'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Continue'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == false) {
      await _abandonExistingQuiz();
    }
  }

  Future<void> _abandonExistingQuiz() async {
    if (_activeQuizId != null) {
      final supabase = Supabase.instance.client;
      await supabase
          .from('quiz_sessions')
          .update({'completed': true}).eq('id', _activeQuizId!);

      safeSetState(() {
        _activeQuizId = null;
        _difficultySelected = false;
        _selectedDifficulty = null;
        questions.clear();
      });
    }
  }

  Future<void> _updateQuizProgress(int currentQuestion, int score) async {
    if (_activeQuizId != null) {
      final supabase = Supabase.instance.client;
      await supabase.from('quiz_sessions').update({
        'current_question': currentQuestion + 1,
        'score': score,
        'questions': jsonEncode(questions.map((q) => q.toJson()).toList()),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _activeQuizId!);
    }
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      safeSetState(() {
        _currentQuestionIndex++;
        _hasAnswered = questions[_currentQuestionIndex].selectedAnswer != null;
        _showAnswer = _selectedDifficulty == 'advanced';
      });
    }
  }

  void _moveToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      safeSetState(() {
        _currentQuestionIndex--;
        _hasAnswered = questions[_currentQuestionIndex].selectedAnswer != null;
        _showAnswer = _selectedDifficulty == 'advanced';
      });
    }
  }

  Future<void> _completeQuiz() async {
    if (_activeQuizId != null) {
      final supabase = Supabase.instance.client;

      await supabase.from('quiz_sessions').update({
        'completed': true,
        'score': _score,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _activeQuizId!);

      final user = supabase.auth.currentUser;
      if (user != null) {
        final currentProfile = await supabase
            .from('profile')
            .select('score')
            .eq('id', user.id)
            .single();

        // Calculate total possible score (10 points per question)
        final totalPossibleScore = questions.length * QUIZPOINT;

        // Calculate score percentage
        final scorePercentage = (_score / totalPossibleScore) * 100;

        // Get current profile score, defaulting to 0 if null
        final currentProfileScore = currentProfile['score'] ?? 0;

        // Check conditions for score penalty:
        // 1. Current profile score > 500
        // 2. Quiz score < 40%
        if (currentProfileScore > 500 && scorePercentage < 40) {
          // Show penalty notification to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Score penalty applied: -15 points (scored below 40% with profile score above 500)'),
                duration: Duration(seconds: 20),
                backgroundColor: Colors.red,
              ),
            );
          }
          await supabase.from('profile').update({
            'score': currentProfile['score'] - 15,
          }).eq('id', user.id);
        } else {
          await supabase.from('profile').update({
            'score': (currentProfile['score'] ?? 0) + _score,
          }).eq('id', user.id);
        }
      }
    }
    _showQuizCompletionDialog();
    _timer?.cancel();
  }

  Future<void> _showQuizCompletionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quiz Completed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Final Score: $_score',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Where would you like to go?'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('View Leaderboard'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to leaderboard
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhynixDashboard(),
                    settings: const RouteSettings(
                        arguments: 2), // Index 2 is for leaderboard
                  ),
                );
              },
            ),
            TextButton(
              child: const Text('Back to Home'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to dashboard with home tab selected
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhynixDashboard(),
                    settings: const RouteSettings(
                        arguments: 0), // Index 0 is for home
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _loadingMessages[_currentMessageIndex],
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.amber),
              ),
            ],
          ),
        ),
      );
    }

    if (!_difficultySelected) {
      return _DifficultySelectionView(
        onDifficultySelected: (difficulty) => _createNewQuiz(difficulty),
      );
    }

    if (_currentQuestionIndex >= questions.length) {
      return const Scaffold(
        body: Center(child: Text('No questions available')),
      );
    }

    return _QuizContentView(
      currentQuestionIndex: _currentQuestionIndex,
      totalQuestions: questions.length,
      question: questions[_currentQuestionIndex],
      selectedAnswerIndex: questions[_currentQuestionIndex].selectedAnswer,
      hasAnswered: _hasAnswered,
      onAnswerSelected: _handleAnswerSelection,
      onNextPressed: _moveToNextQuestion,
      onPreviousPressed: _moveToPreviousQuestion,
      onComplete: _completeQuiz,
      showResults: _showResults,
      timeRemaining: _selectedDifficulty != 'beginner' ? formattedTime : null,
      canEndEarly: canEndQuizEarly(),
      onEndEarly: _showEndQuizEarlyDialog,
      showAnswer: _showAnswer && _selectedDifficulty == 'advanced',
      canChangeAnswer: _canChangeAnswer,
    );
  }
}

// Modify _QuizContentView to include new parameters
class _QuizContentView extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final QuizQuestion question;
  final int? selectedAnswerIndex;
  final bool hasAnswered;
  final Function(int) onAnswerSelected;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onComplete;
  final bool showResults;
  final String? timeRemaining;
  final bool canEndEarly;
  final VoidCallback onEndEarly;
  final bool showAnswer;
  final bool canChangeAnswer;

  const _QuizContentView({
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.question,
    required this.selectedAnswerIndex,
    required this.hasAnswered,
    required this.onAnswerSelected,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.onComplete,
    required this.showResults,
    this.timeRemaining,
    required this.canEndEarly,
    required this.onEndEarly,
    required this.showAnswer,
    required this.canChangeAnswer,
  });

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).primaryColor;
    List<MapEntry<String, dynamic>> options = question.options.entries.toList();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Physics Quiz',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (canEndEarly)
              TextButton(
                onPressed: onEndEarly,
                child: const Text('End Quiz'),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress, Score, and Timer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${currentQuestionIndex + 1}/$totalQuestions',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (timeRemaining != null)
                      Text(
                        timeRemaining!,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Question Image
              if (question.imageUrl != null && question.imageUrl!.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      question.imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error);
                      },
                    ),
                  ),
                ),

              // Question Text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 20),

              // Keep the rest of the build method the same...
              // Just update the _buildOptionButton call to include showAnswer:
              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    bool isCorrect = options[index].key.toLowerCase() ==
                        question.correctAnswer.toLowerCase();
                    return _buildOptionButton(
                      context,
                      primaryColor,
                      index,
                      options[index].value,
                      selectedAnswerIndex == index,
                      isCorrect && showAnswer,
                      () => onAnswerSelected(index),
                    );
                  },
                ),
              ),

              // Keep the navigation buttons section the same...
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed:
                          currentQuestionIndex > 0 ? onPreviousPressed : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Previous'),
                    ),
                    if (!showResults &&
                        currentQuestionIndex == totalQuestions - 1)
                      ElevatedButton(
                        onPressed: hasAnswered ? onComplete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Submit Quiz'),
                      )
                    else if (!showResults)
                      ElevatedButton(
                        onPressed: hasAnswered ? onNextPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Next'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keep the _buildOptionButton method the same...
  Widget _buildOptionButton(
    BuildContext context,
    Color primaryColor,
    int index,
    dynamic text,
    bool isSelected,
    bool isCorrect,
    VoidCallback onTap,
  ) {
    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;

    if (hasAnswered && showAnswer) {
      if (isCorrect) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
      } else if (isSelected) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
      }
    } else if (isSelected) {
      backgroundColor = primaryColor.withOpacity(0.1);
      borderColor = primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: (showAnswer && hasAnswered) ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.white,
                  border: Border.all(color: primaryColor),
                ),
                child: Center(
                  child: Text(
                    String.fromCharCode(65 + index),
                    style: TextStyle(
                      color: isSelected ? Colors.white : primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              if (hasAnswered && showAnswer)
                Icon(
                  isCorrect
                      ? Icons.check_circle
                      : (isSelected ? Icons.cancel : null),
                  color: isCorrect
                      ? Colors.green
                      : (isSelected ? Colors.red : null),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySelectionView extends StatelessWidget {
  final Function(String) onDifficultySelected;

  const _DifficultySelectionView({
    required this.onDifficultySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Level',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              _buildLevelCard(
                context,
                title: 'Beginner',
                description: 'Perfect for those new to physics',
                details: 'Basic concepts and fundamental principles',
                timeEstimate: 'No limit',
                onTap: () => onDifficultySelected('beginner'),
              ),
              const SizedBox(height: 16),
              _buildLevelCard(
                context,
                title: 'Intermediate',
                description: 'For those who have a grasp of physics',
                details: 'Less-complex problems and intermediate theories',
                timeEstimate: '60 minutes',
                onTap: () => onDifficultySelected('intermediate'),
              ),
              const SizedBox(height: 16),
              _buildLevelCard(
                context,
                title: 'Advanced',
                description: 'For experienced physics enthusiasts',
                details: 'Complex problems and advanced theories',
                timeEstimate: '30 minutes',
                onTap: () => onDifficultySelected('advanced'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String title,
    required String description,
    required String details,
    required String timeEstimate,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      color: Colors.grey[200],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                details,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeEstimate,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
