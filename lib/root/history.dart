// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:convert';

// // Quiz History List Page
// class QuizHistoryPage extends StatelessWidget {
//   final supabase = Supabase.instance.client;

//   QuizHistoryPage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Quiz History'),
//         backgroundColor: const Color(0xFF264653),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _fetchQuizHistory(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }

//           final quizzes = snapshot.data ?? [];

//           if (quizzes.isEmpty) {
//             return const Center(
//               child: Text('No completed quizzes found'),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16),
//             itemCount: quizzes.length,
//             itemBuilder: (context, index) {
//               final quiz = quizzes[index];
//               return Card(
//                 elevation: 4,
//                 margin: const EdgeInsets.only(bottom: 16),
//                 child: ListTile(
//                   title: Text(
//                     'Quiz: ${quiz['subject']}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('Difficulty: ${quiz['difficulty']}'),
//                       Text(
//                           'Score: ${quiz['score']}/${quiz['total_questions']}'),
//                       Text(
//                           'Date: ${DateTime.parse(quiz['created_at']).toString().split('.')[0]}'),
//                     ],
//                   ),
//                   trailing: Icon(
//                     Icons.chevron_right,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => QuizDetailPage(quizSession: quiz),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Future<List<Map<String, dynamic>>> _fetchQuizHistory() async {
//     final user = supabase.auth.currentUser;
//     if (user == null) throw Exception('User not authenticated');

//     final response = await supabase
//         .from('quiz_sessions')
//         .select()
//         .eq('user_id', user.id)
//         .eq('completed', true)
//         .order('created_at', ascending: false);

//     return List<Map<String, dynamic>>.from(response);
//   }
// }

// // Quiz Detail Page
// class QuizDetailPage extends StatelessWidget {
//   final Map<String, dynamic> quizSession;

//   const QuizDetailPage({Key? key, required this.quizSession}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final questions = List<Map<String, dynamic>>.from(
//       jsonDecode(quizSession['questions'].toString()),
//     );

//     return Scaffold(
//       appBar: AppBar(
//         title: Text('${quizSession['subject']} Quiz Details'),
//         backgroundColor: const Color(0xFF264653),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildSummaryCard(),
//             const SizedBox(height: 24),
//             const Text(
//               'Questions & Answers',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ...questions
//                 .map((question) => _buildQuestionCard(question))
//                 .toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryCard() {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Quiz Summary',
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.orange,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildSummaryRow('Subject', quizSession['subject']),
//             _buildSummaryRow('Difficulty', quizSession['difficulty']),
//             _buildSummaryRow('Score',
//                 '${quizSession['score']}/${quizSession['total_questions']}'),
//             _buildSummaryRow(
//                 'Date',
//                 DateTime.parse(quizSession['created_at'])
//                     .toString()
//                     .split('.')[0]),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSummaryRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuestionCard(Map<String, dynamic> question) {
//     final userAnswer = question['user_answer'] ?? 'Not answered';
//     final isCorrect = question['correct_answer'] == userAnswer;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               question['question'],
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//             _buildAnswerRow('Your Answer', userAnswer, isCorrect),
//             const SizedBox(height: 8),
//             _buildAnswerRow('Correct Answer', question['correct_answer'], true),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
//     return Row(
//       children: [
//         Text(
//           '$label: ',
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         Text(
//           answer,
//           style: TextStyle(
//             color: label == 'Your Answer'
//                 ? (isCorrect ? Colors.green : Colors.red)
//                 : Colors.green,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class QuizHistoryPage extends StatefulWidget {
  QuizHistoryPage({Key? key}) : super(key: key);

  @override
  _QuizHistoryPageState createState() => _QuizHistoryPageState();
}

class _QuizHistoryPageState extends State<QuizHistoryPage> {
  final supabase = Supabase.instance.client;
  String? selectedSubject;
  final List<String> subjects = ['Mathematics', 'Chemistry', 'Physics'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        backgroundColor: const Color(0xFF264653),
      ),
      body: Column(
        children: [
          _buildSubjectFilter(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchQuizHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final quizzes = snapshot.data ?? [];

                if (quizzes.isEmpty) {
                  return const Center(
                    child: Text('No completed quizzes found'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(
                          'Quiz: ${quiz['subject']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Difficulty: ${quiz['difficulty']}'),
                            Text(
                                'Score: ${quiz['score']}/${quiz['total_questions']}'),
                            Text(
                                'Date: ${DateTime.parse(quiz['created_at']).toString().split('.')[0]}'),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  QuizDetailPage(quizSession: quiz),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Subject:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: selectedSubject == null,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedSubject = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...subjects.map((subject) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(subject),
                        selected: selectedSubject == subject,
                        onSelected: (bool selected) {
                          setState(() {
                            selectedSubject =
                                selected ? subject.toLowerCase() : null;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchQuizHistory() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    var query = supabase
        .from('quiz_sessions')
        .select()
        .eq('user_id', user.id)
        .eq('completed', true);

    // Add subject filter before the order
    if (selectedSubject != null) {
      query = query.eq('subject', selectedSubject as String);
    }

    // Add order as the final operation
    final response = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

class QuizDetailPage extends StatelessWidget {
  final Map<String, dynamic> quizSession;

  const QuizDetailPage({Key? key, required this.quizSession}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final questions = List<Map<String, dynamic>>.from(
        jsonDecode(quizSession['questions'].toString()));

    return Scaffold(
      appBar: AppBar(
        title: Text('${quizSession['subject']} Quiz Details'),
        backgroundColor: const Color(0xFF264653),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            const Text(
              'Questions & Answers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...questions
                .map((question) => _buildQuestionCard(question))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiz Summary',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subject', quizSession['subject']),
            _buildSummaryRow('Difficulty', quizSession['difficulty']),
            _buildSummaryRow('Score',
                '${quizSession['score']}/${quizSession['total_questions']}'),
            _buildSummaryRow(
                'Date',
                DateTime.parse(quizSession['created_at'])
                    .toString()
                    .split('.')[0]),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final userAnswer = question['selectedAnswer'] != null
        ? question['options']
            ['${['a', 'b', 'c', 'd'][question['selectedAnswer']]}'.trim()]
        : 'Not answered';
    final correctAnswer = question['options'][question['answer']].trim();
    final isCorrect = userAnswer == correctAnswer;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question['question'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Show options
            ...['a', 'b', 'c', 'd']
                .map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${option.toUpperCase()}. ${question['options'][option]}',
                        style: TextStyle(
                          color: userAnswer == question['options'][option]
                              ? (isCorrect ? Colors.green : Colors.red)
                              : correctAnswer == question['options'][option]
                                  ? Colors.green
                                  : null,
                        ),
                      ),
                    ))
                .toList(),
            const SizedBox(height: 16),
            _buildAnswerRow('Your Answer', userAnswer, isCorrect),
            const SizedBox(height: 8),
            _buildAnswerRow('Correct Answer', correctAnswer, true),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            answer,
            style: TextStyle(
              color: label == 'Your Answer'
                  ? (isCorrect ? Colors.green : Colors.red)
                  : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildQuestionCard(Map<String, dynamic> question) {
  //   print(question);
  //   final userAnswer = question['selectedAnswer'] ?? 'Not answered';
  //   // Handle potential null correct_answer
  //   final correctAnswer =
  //       question['correct_answer']?.toString() ?? 'No answer provided';
  //   final isCorrect = correctAnswer != 'No answer provided' &&
  //       question['correct_answer'] == userAnswer;

  //   return Card(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             question['question'],
  //             style: const TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 16),
  //           _buildAnswerRow('Your Answer', userAnswer, isCorrect),
  //           const SizedBox(height: 8),
  //           _buildAnswerRow('Correct Answer', correctAnswer, true),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildAnswerRow(String label, String answer, bool isCorrect) {
  //   return Row(
  //     children: [
  //       Text(
  //         '$label: ',
  //         style: const TextStyle(
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       Expanded(
  //         child: Text(
  //           answer,
  //           style: TextStyle(
  //             color: label == 'Your Answer'
  //                 ? (isCorrect ? Colors.green : Colors.red)
  //                 : Colors.green,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
