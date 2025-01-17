import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgeModel {
  final String name;
  final String icon;
  final int requiredQuestions;
  final String description;

  BadgeModel({
    required this.name,
    required this.icon,
    required this.requiredQuestions,
    required this.description,
  });
}

class BadgeSystem {
  static final List<BadgeModel> badges = [
    BadgeModel(
      name: 'Rookie',
      icon: '🥉',
      requiredQuestions: 10,
      description: 'Completed 10 quizzes',
    ),
    BadgeModel(
      name: 'Bronze Star',
      icon: '⭐',
      requiredQuestions: 25,
      description: 'Completed 25 quizzes',
    ),
    BadgeModel(
      name: 'Silver Scholar',
      icon: '🥈',
      requiredQuestions: 50,
      description: 'Completed 50 quizzes',
    ),
    BadgeModel(
      name: 'Gold Champion',
      icon: '🥇',
      requiredQuestions: 100,
      description: 'Completed 100 quizzes',
    ),
    BadgeModel(
      name: 'Quiz Master',
      icon: '👑',
      requiredQuestions: 200,
      description: 'Completed 200 quizzes',
    ),
    BadgeModel(
      name: 'Knowledge Seeker',
      icon: '🎯',
      requiredQuestions: 300,
      description: 'Completed 300 quizzes',
    ),
    BadgeModel(
      name: 'Wisdom Sage',
      icon: '🏅',
      requiredQuestions: 400,
      description: 'Completed 400 quizzes',
    ),
    BadgeModel(
      name: 'Grand Scholar',
      icon: '🎓',
      requiredQuestions: 500,
      description: 'Completed 500 quizzes',
    ),
    BadgeModel(
      name: 'Ultimate Master',
      icon: '🏆',
      requiredQuestions: 1000,
      description: 'Completed 1000 quizzes',
    ),
  ];

  static List<BadgeModel> getEarnedBadges(int completedQuestions) {
    return badges
        .where((badge) => completedQuestions >= badge.requiredQuestions)
        .toList();
  }

  static BadgeModel? getNextBadge(int completedQuestions) {
    return badges.firstWhere(
      (badge) => completedQuestions < badge.requiredQuestions,
      orElse: () => badges.last,
    );
  }
}

class BadgesPage extends StatelessWidget {
  final supabase = Supabase.instance.client;

  BadgesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Achievement'),
        backgroundColor: const Color(0xFF264653),
      ),
      body: FutureBuilder<int>(
        future: _getCompletedQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final completedQuestions = snapshot.data ?? 0;
          final earnedBadges = BadgeSystem.getEarnedBadges(completedQuestions);
          final nextBadge = BadgeSystem.getNextBadge(completedQuestions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quizzes Completed: $completedQuestions',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Earned Badges (${earnedBadges.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: earnedBadges.length,
                  itemBuilder: (context, index) {
                    return _buildBadgeCard(earnedBadges[index], true);
                  },
                ),
                if (nextBadge != null && !earnedBadges.contains(nextBadge)) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Next Badge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBadgeCard(nextBadge, false),
                  Text(
                    '${nextBadge.requiredQuestions - completedQuestions} more quizzes to unlock',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge, bool earned) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: earned ? Colors.white10 : Colors.black12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              badge.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: earned ? Colors.white : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 12,
                color: earned ? Colors.white70 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getCompletedQuestions() async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final response = await supabase
        .from('quiz_sessions')
        .select('count') // Changed to use count
        .eq('user_id', user.id)
        .eq('completed', true)
        .single(); // Use single() to get a single response

    return response['count'] as int; // Return the count directly
  }
}

// Badge Progress Widget for showing in other pages
class BadgeProgressWidget extends StatelessWidget {
  final int completedQuestions;

  const BadgeProgressWidget({
    Key? key,
    required this.completedQuestions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextBadge = BadgeSystem.getNextBadge(completedQuestions);
    if (nextBadge == null) return const SizedBox.shrink();

    final progress = completedQuestions / nextBadge.requiredQuestions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  nextBadge.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Next Badge: ${nextBadge.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
            const SizedBox(height: 4),
            Text(
              '${completedQuestions}/${nextBadge.requiredQuestions} quizzes completed',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
