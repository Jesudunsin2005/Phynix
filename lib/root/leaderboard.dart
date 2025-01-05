import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  LeaderboardPageState createState() => LeaderboardPageState();
}

class LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
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

  Future<void> _fetchLeaderboardData() async {
    try {
      final supabase = Supabase.instance.client;

      // First, get the current user's level
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final currentUserProfile = await supabase
          .from('profile')
          .select('current_level')
          .eq('id', currentUser.id)
          .single();

      final currentLevel = currentUserProfile['current_level'];

      // Then fetch leaderboard data filtered by the current level
      final response = await supabase
          .from('profile')
          .select('username, score, current_level')
          .eq('current_level', currentLevel) // Filter by current level
          .order('score', ascending: false)
          .limit(20);

      safeSetState(() {
        _leaderboardData = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching leaderboard data: $e');
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTopThree() {
    if (_leaderboardData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_leaderboardData.length >= 2)
            _buildTopPlayer(_leaderboardData[1], 2, 140)
          else
            const SizedBox(width: 80),
          _buildTopPlayer(_leaderboardData[0], 1, 160),
          if (_leaderboardData.length >= 3)
            _buildTopPlayer(_leaderboardData[2], 3, 120)
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildTopPlayer(
      Map<String, dynamic> player, int position, double height) {
    Color podiumColor;
    IconData trophyIcon;
    switch (position) {
      case 1:
        podiumColor = Colors.amber.shade400;
        trophyIcon = Icons.emoji_events;
        break;
      case 2:
        podiumColor = Colors.grey.shade300;
        trophyIcon = Icons.emoji_events;
        break;
      case 3:
        podiumColor = Colors.brown.shade300;
        trophyIcon = Icons.emoji_events;
        break;
      default:
        podiumColor = Colors.grey;
        trophyIcon = Icons.emoji_events;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            CircleAvatar(
              radius: position == 1 ? 35 : 30,
              backgroundColor: podiumColor,
              child: CircleAvatar(
                radius: position == 1 ? 32 : 27,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                  size: position == 1 ? 40 : 30,
                ),
              ),
            ),
            if (position <= 3)
              Transform.translate(
                offset: const Offset(0, -15),
                child: Icon(
                  trophyIcon,
                  color: podiumColor,
                  size: position == 1 ? 30 : 24,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          player['username'] ?? 'User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: position == 1 ? 16 : 14,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${player['score']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                podiumColor,
                podiumColor.withOpacity(0.7),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: podiumColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    final startIndex = _leaderboardData.length <= 3 ? 0 : 3;

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _leaderboardData.length - startIndex,
        itemBuilder: (context, index) {
          final actualIndex = index + startIndex;
          final player = _leaderboardData[actualIndex];

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey.shade200,
                  Colors.grey.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${actualIndex + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                player['username'] ?? 'User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              subtitle: Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    player['current_level'] ?? 'Beginner',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                    ),
                  ),
                ],
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${player['score']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(87, 67, 63, 63),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_leaderboardData.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No leaderboard data available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _buildTopThree(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(
                  thickness: 1,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              _buildLeaderboardList(),
            ],
          ],
        ),
      ),
    );
  }
}
