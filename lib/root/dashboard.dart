import 'package:flutter/material.dart';
import 'package:phynix/root/badge.dart';
import 'package:phynix/root/leaderboard.dart';
import 'package:phynix/root/profile.dart';
import 'package:phynix/root/quiz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhynixDashboard extends StatefulWidget {
  const PhynixDashboard({super.key});

  @override
  _PhynixDashboardState createState() => _PhynixDashboardState();
}

class _PhynixDashboardState extends State<PhynixDashboard> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    // Get initial index from route arguments, default to 0 if not provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is int) {
        setState(() {
          _selectedIndex = arguments;
        });
      }
    });
  }

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    const MainDashboardContent(),
    const QuizPage(),
    const LeaderboardPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer_outlined),
            label: 'Q/A',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Me',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class MainDashboardContent extends StatefulWidget {
  const MainDashboardContent({super.key});

  @override
  _MainDashboardContentState createState() => _MainDashboardContentState();
}

class _MainDashboardContentState extends State<MainDashboardContent> {
  String _username = 'User';
  int _totalScore = 0;
  String _currentLevel = '';
  bool _mounted = true;

  // Add state variables for difficulty stats
  final Map<String, Map<String, Map<String, String>>> _subjectStats = {
    'physics': {
      'beginner': {'score': '0', 'count': '0'},
      'intermediate': {'score': '0', 'count': '0'},
      'advanced': {'score': '0', 'count': '0'},
    },
    'mathematics': {
      'beginner': {'score': '0', 'count': '0'},
      'intermediate': {'score': '0', 'count': '0'},
      'advanced': {'score': '0', 'count': '0'},
    },
    'chemistry': {
      'beginner': {'score': '0', 'count': '0'},
      'intermediate': {'score': '0', 'count': '0'},
      'advanced': {'score': '0', 'count': '0'},
    },
  };
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (_mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user != null) {
      safeSetState(() {
        _username = user.userMetadata?['username'] ??
            user.userMetadata?['fullname'] ??
            user.email?.split('@').first ??
            'User';
      });

      print(user);

      final profileResponse = await supabase
          .from('profile')
          .select('*')
          .eq('id', user.id)
          .limit(1)
          .maybeSingle();

      if (profileResponse == null) {
        // Profile does not exist, create a new one
        final insertResponse = await supabase.from('profile').insert({
          'id': user.id,
          'username': _username,
        });

        if (insertResponse?["error"] != null) {
          // Handle error
          print(insertResponse?["error"].message);
        } else {
          print('New profile created');
          safeSetState(() {
            _currentLevel = "Beginner";
            _totalScore = 0;
          });
        }
      } else {
        // Profile exists
        safeSetState(() {
          _currentLevel = profileResponse["current_level"];
          _totalScore = profileResponse["score"];
        });
      }

      // Get the start of current week
      final now = DateTime.now().toUtc();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDate =
          DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      try {
        // Fetch quiz statistics for all subjects
        for (String subject in _subjectStats.keys) {
          final response = await supabase
              .from('quiz_sessions')
              .select()
              .eq('user_id', user.id)
              .eq('subject', subject)
              .gte('created_at', startOfWeekDate.toIso8601String())
              .lt('created_at', now.toIso8601String());

          // Group sessions by difficulty for each subject
          final Map<String, List<Map<String, dynamic>>> groupedSessions = {
            'beginner': [],
            'intermediate': [],
            'advanced': [],
          };

          for (var session in response) {
            String difficulty = session['difficulty'];
            if (groupedSessions.containsKey(difficulty)) {
              groupedSessions[difficulty]!.add(session);
            }
          }

          // Calculate statistics for each difficulty within the subject
          safeSetState(() {
            groupedSessions.forEach((difficulty, sessions) {
              if (sessions.isEmpty) {
                _subjectStats[subject]![difficulty] = {
                  'score': '0',
                  'count': '0'
                };
              } else {
                double avgScore = sessions
                        .map((s) => s['score'] as int)
                        .reduce((a, b) => a + b) /
                    sessions.length;

                _subjectStats[subject]![difficulty] = {
                  'score': avgScore.toStringAsFixed(1),
                  'count': sessions.length.toString()
                };
              }
            });
          });
        }
      } catch (e) {
        print('Error fetching quiz statistics: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor = Theme.of(context).primaryColor;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(
                children: [
                  Text('Hello ',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black)),
                  Text(_username,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black))
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/quiz-history');
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (context) => QuizHistoryPage()),
                  // );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical:
                          8.0), // Add some padding for better touch target
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_sharp,
                        size: 24.0,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ]),
            const SizedBox(height: 16),
            Card(
              color: primaryColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 24.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return IntrinsicHeight(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Score',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_totalScore',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const VerticalDivider(
                            color: Colors.white24,
                            thickness: 1,
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Current Level',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentLevel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              color: primaryColor,
              height: 5,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    _buildSubjectSection('Physics'),
                    const SizedBox(height: 16),
                    _buildSubjectSection('Mathematics'),
                    const SizedBox(height: 16),
                    _buildSubjectSection('Chemistry'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Divider(
                      color: primaryColor,
                      height: 5,
                    ),
                    // _buildOffersAndRewardsSection(context),
                    const SizedBox(height: 16),
                    const AchievementsWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSection(String subject) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subject,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDifficultyRow('Beginner',
                    _subjectStats[subject.toLowerCase()]!['beginner']!),
                const Divider(),
                _buildDifficultyRow('Intermediate',
                    _subjectStats[subject.toLowerCase()]!['intermediate']!),
                const Divider(),
                _buildDifficultyRow('Advanced',
                    _subjectStats[subject.toLowerCase()]!['advanced']!),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyRow(String level, Map<String, String> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            level,
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.black),
          ),
          Text(
            'Score: ${stats['score']}% (${stats['count']} quizzes)',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildOffersAndRewardsSection(context) {
  //   Color primaryColor = Theme.of(context).primaryColor;

  //   return Card(
  //     color: Colors.grey[200],
  //     child: Padding(
  //       padding: const EdgeInsets.only(
  //           top: 16.0, bottom: 16.0, left: 10.0, right: 10.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'Complete Offers & Gain Rewards',
  //             style: TextStyle(
  //               fontSize: 16,
  //               fontWeight: FontWeight.bold,
  //               color: primaryColor,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           _buildOfferRow('Daily Check-in', '2', context),
  //           const SizedBox(height: 8),
  //           _buildOfferRow('Get 5 questions at a go', '7', context),
  //           const SizedBox(height: 8),
  //           _buildOfferRow('Get 10 questions at a go', '2', context),
  //           const SizedBox(height: 8),
  //           _buildOfferRow('Complete level', '15', context),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildOfferRow(String title, String reward, context) {
  //   Color primaryColor = Theme.of(context).primaryColor;

  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     children: [
  //       Text(
  //         title,
  //         style: const TextStyle(fontSize: 14, color: Colors.black),
  //       ),
  //       Container(
  //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //         decoration: BoxDecoration(
  //           color: primaryColor,
  //           borderRadius: BorderRadius.circular(4),
  //         ),
  //         child: Row(
  //           children: [
  //             Icon(
  //               Icons.stars,
  //               color: Colors.grey[200],
  //               size: 16,
  //             ),
  //             const SizedBox(width: 4),
  //             Text(
  //               reward,
  //               style: const TextStyle(
  //                 fontSize: 14,
  //                 color: Color.fromARGB(255, 238, 238, 238),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
}

class AchievementsWidget extends StatelessWidget {
  static final supabase = Supabase.instance.client;

  const AchievementsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return FutureBuilder<int>(
      future: _getCompletedQuestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final completedQuestions = snapshot.data ?? 0;
        final earnedBadges = BadgeSystem.getEarnedBadges(completedQuestions);
        final displayBadges = earnedBadges.length > 3
            ? earnedBadges.sublist(earnedBadges.length - 3)
            : earnedBadges;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Achievements",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BadgesPage(),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (displayBadges.isEmpty)
                const Text(
                  "Complete quizzes to earn badges!",
                  style: TextStyle(color: Colors.grey),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < displayBadges.length; i++) ...[
                      _buildBadgeItem(displayBadges[i]),
                      if (i < displayBadges.length - 1)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadgeItem(BadgeModel badge) {
    return Tooltip(
      message: badge.description,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            badge.icon,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Future<int> _getCompletedQuestions() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('quiz_sessions')
        .select('count')
        .eq('user_id', user.id)
        .eq('completed', true)
        .single();

    return response['count'] as int;
  }
}
