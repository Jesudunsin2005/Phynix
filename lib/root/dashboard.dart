import 'package:flutter/material.dart';
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
  String _currentLevel = 'Beginner';
  bool _mounted = true;

  // Add state variables for difficulty stats
  final Map<String, Map<String, String>> _difficultyStats = {
    'beginner': {'score': '0', 'count': '0'},
    'intermediate': {'score': '0', 'count': '0'},
    'advanced': {'score': '0', 'count': '0'},
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
        // Fetch quiz statistics for current week
        final response = await supabase
            .from('quiz_sessions')
            .select()
            .eq('user_id', user.id)
            .gte('created_at', startOfWeekDate.toIso8601String())
            .lt('created_at', now.toIso8601String());

        // Group sessions by difficulty
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

        // Calculate statistics for each difficulty
        safeSetState(() {
          groupedSessions.forEach((difficulty, sessions) {
            if (sessions.isEmpty) {
              _difficultyStats[difficulty] = {'score': '0', 'count': '0'};
            } else {
              // Calculate average score
              double avgScore = sessions
                      .map((s) => s['score'] as int)
                      .reduce((a, b) => a + b) /
                  sessions.length;

              _difficultyStats[difficulty] = {
                'score': avgScore.toStringAsFixed(1),
                'count': sessions.length.toString()
              };
            }
          });
        });
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
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: 24.0,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '20',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
                    const AchievementsWidget(),
                    const SizedBox(height: 16),
                    Divider(
                      color: primaryColor,
                      height: 5,
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Beginner Level',
                      _difficultyStats['beginner']!['score']!,
                      '${_difficultyStats['beginner']!['count']} Quizzes',
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Intermediate Level',
                      _difficultyStats['intermediate']!['score']!,
                      '${_difficultyStats['intermediate']!['count']!} Quizzes',
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Advanced Level',
                      _difficultyStats['advanced']!['score']!,
                      '${_difficultyStats['advanced']!['count']!} Quizzes',
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildOffersAndRewardsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyCard(String title, String score, String count) {
    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg score: $score',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed: $count',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOffersAndRewardsSection(context) {
    Color primaryColor = Theme.of(context).primaryColor;

    return Card(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.only(
            top: 16.0, bottom: 16.0, left: 10.0, right: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Complete Offers & Gain Rewards',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            _buildOfferRow('Daily Check-in', '2', context),
            const SizedBox(height: 8),
            _buildOfferRow('Get 5 questions at a go', '7', context),
            const SizedBox(height: 8),
            _buildOfferRow('Get 10 questions at a go', '2', context),
            const SizedBox(height: 8),
            _buildOfferRow('Complete level', '15', context),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferRow(String title, String reward, context) {
    Color primaryColor = Theme.of(context).primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.stars,
                color: Colors.grey[200],
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                reward,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 238, 238, 238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AchievementsWidget extends StatelessWidget {
  const AchievementsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Achievements",
          style: TextStyle(
              fontSize: 20, color: primaryColor, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.asset(
                  'assets/shark.png',
                  width: 50,
                  height: 50,
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'x2',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/yolo.png',
              width: 50,
              height: 50,
            ),
          ],
        ),
      ],
    );
  }
}
