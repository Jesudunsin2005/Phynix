import 'package:flutter/material.dart';
import 'package:phynix/root/leaderboard.dart';
import 'package:phynix/root/profile.dart';
import 'package:phynix/root/quiz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhynixDashboard extends StatefulWidget {
  const PhynixDashboard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PhynixDashboardState createState() => _PhynixDashboardState();
}

class _PhynixDashboardState extends State<PhynixDashboard> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Get initial index from route arguments, default to 0 if not provided
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arguments = ModalRoute.of(context)?.settings.arguments;
      if (arguments != null && arguments is int) {
        setState(() {
          _selectedIndex = arguments;
        });
      }
    });
    _selectedIndex = 0;
  }

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    _MainDashboardContent(),
    QuizPage(),
    LeaderboardPage(),
    ProfilePage(),
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
        type: BottomNavigationBarType.fixed, // This is important
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

class _MainDashboardContent extends StatefulWidget {
  const _MainDashboardContent();

  @override
  __MainDashboardContentState createState() => __MainDashboardContentState();
}

class __MainDashboardContentState extends State<_MainDashboardContent> {
  String _username = 'User';
  int _totalScore = 0;
  String _currentLevel = 'Beginner';
  bool _mounted = true;

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
      setState(() {
        _username = user.userMetadata?['username'] ??
            user.userMetadata?['fullname'] ??
            user.email?.split('@').first ??
            'User';
      });

      final response = await supabase
          .from('profile')
          .select('*')
          .eq('id', user.id)
          .limit(1)
          .maybeSingle();

      print(response);
      if (response == null) {
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
          print(insertResponse);
          safeSetState(() {
            _currentLevel = "Beginner";
            _totalScore = 0;
          });
        }
      } else {
        // Profile exists
        safeSetState(() {
          _currentLevel = response["current_level"];
          _totalScore = response["score"];
        });
      }

      print(_username);
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
            SizedBox(
              height: 100,
              child: Card(
                color: primaryColor,
                child: Padding(
                  padding: const EdgeInsets.only(
                      top: 16.0, bottom: 16.0, left: 30.0, right: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text('Total Score',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  )),
                              Text('$_totalScore',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ))
                            ],
                          ),
                          Column(
                            children: [
                              Text('Current Level',
                                  style: const TextStyle(
                                    fontSize: 16,
                                  )),
                              Text(_currentLevel,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ))
                            ],
                          )
                        ],
                      )
                    ],
                  ),
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
                    AchievementsWidget(),
                    const SizedBox(height: 16),
                    Divider(
                      color: primaryColor,
                      height: 5,
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Beginner Level',
                      '50',
                      '1hrs 30mins',
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Intermediate Level',
                      '50',
                      '1hrs',
                    ),
                    const SizedBox(height: 16),
                    _buildDifficultyCard(
                      'Advanced Level',
                      '50',
                      '30mins',
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

  Widget _buildDifficultyCard(
    String title,
    String score,
    String duration,
  ) {
    return SizedBox(
        height: 120,
        child: Card(
          color: Colors.grey[200],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg score: $score',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 8),
                Text(
                  'Avg duration: $duration',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
        ));
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
        SizedBox(height: 10),
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
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'x2',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 10),
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
