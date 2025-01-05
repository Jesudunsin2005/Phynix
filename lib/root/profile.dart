// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   _ProfilePageState createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   final _supabase = Supabase.instance.client;
//   bool _isLoading = true;
//   String _username = '';
//   double _score = 0;
//   String _currentLevel = '';
//   double _balance = 0;
//   int _totalQuizzes = 0;
//   double _monthlyAverage = 0;
//   List<Map<String, dynamic>> _achievements = [];
//   final _usernameController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadProfileData();
//   }

//   Future<void> _loadProfileData() async {
//     try {
//       final userId = _supabase.auth.currentUser!.id;

//       // Load profile data
//       final profileData =
//           await _supabase.from('profile').select().eq('id', userId).single();

//       // Load completed quizzes count
//       final quizCount = await _supabase
//           .from('quiz_sessions')
//           .select('id, score, count(*)')
//           .eq('user_id', userId)
//           .eq('completed', true);

//       // Calculate monthly average
//       final now = DateTime.now();
//       final monthStart = DateTime(now.year, now.month, 1);
//       final monthlyQuizzes = await _supabase
//           .from('quiz_sessions')
//           .select('score')
//           .eq('user_id', userId)
//           .eq('completed', true)
//           .gte('created_at', monthStart.toIso8601String());

//       double monthlyTotal = 0;
//       for (var quiz in monthlyQuizzes) {
//         monthlyTotal += (quiz['score'] as num).toDouble();
//       }

//       // Load achievements
//       final achievements =
//           await _supabase.from('Achievement').select().order('created_at');

//       setState(() {
//         _username = profileData['username'] ?? 'App User';
//         _score = (profileData['score'] ?? 0).toDouble();
//         _currentLevel = profileData['current_level'] ?? 'Beginner';
//         _balance = (profileData['balance'] ?? 0).toDouble();
//         _totalQuizzes = quizCount.count ?? 0;
//         _monthlyAverage =
//             monthlyQuizzes.isEmpty ? 0 : monthlyTotal / monthlyQuizzes.length;
//         _achievements = List<Map<String, dynamic>>.from(achievements);
//         _isLoading = false;
//         _usernameController.text = _username;
//       });
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error loading profile: $error')),
//       );
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _updateUsername() async {
//     try {
//       final userId = _supabase.auth.currentUser!.id;
//       await _supabase
//           .from('profile')
//           .update({'username': _usernameController.text}).eq('id', userId);

//       setState(() => _username = _usernameController.text);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Username updated successfully!')),
//       );
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating username: $error')),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Profile'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Profile Header
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Theme.of(context).colorScheme.secondary,
//                       child: Text(
//                         _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
//                         style: const TextStyle(fontSize: 32),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _usernameController,
//                       decoration: InputDecoration(
//                         labelText: 'Username',
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.save),
//                           onPressed: _updateUsername,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Stats Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Statistics',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildStatTile('Current Level', _currentLevel),
//                     _buildStatTile('Total Score', _score.toString()),
//                     _buildStatTile('Stars Balance', '⭐ ${_balance.toString()}'),
//                     _buildStatTile(
//                         'Completed Quizzes', _totalQuizzes.toString()),
//                     _buildStatTile(
//                       'Monthly Average Score',
//                       _monthlyAverage.toStringAsFixed(1),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             // Achievements Section
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Achievements',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 16),
//                     GridView.builder(
//                       shrinkWrap: true,
//                       physics: const NeverScrollableScrollPhysics(),
//                       gridDelegate:
//                           const SliverGridDelegateWithFixedCrossAxisCount(
//                         crossAxisCount: 3,
//                         crossAxisSpacing: 8,
//                         mainAxisSpacing: 8,
//                       ),
//                       itemCount: _achievements.length,
//                       itemBuilder: (context, index) {
//                         final achievement = _achievements[index];
//                         return Tooltip(
//                           message: achievement['achievement_name'] ?? '',
//                           child: Card(
//                             child: Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Image.network(
//                                 achievement['img_url'],
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return const Icon(Icons.error);
//                                 },
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatTile(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label),
//           Text(
//             value,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _username = '';
  double _score = 0;
  String _currentLevel = '';
  double _balance = 0;
  int _totalQuizzes = 0;
  double _monthlyAverage = 0;
  List<Map<String, dynamic>> _achievements = [];
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      // Load profile data
      final profileData =
          await _supabase.from('profile').select().eq('id', userId).single();

      // Load completed quizzes count and calculate total
      final quizResponse = await _supabase
          .from('quiz_sessions')
          .select('score')
          .eq('user_id', userId)
          .eq('completed', true);

      final List<Map<String, dynamic>> quizzes =
          List<Map<String, dynamic>>.from(quizResponse);
      final int completedQuizCount = quizzes.length;

      // Calculate monthly average
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthlyQuizzesResponse = await _supabase
          .from('quiz_sessions')
          .select('score')
          .eq('user_id', userId)
          .eq('completed', true)
          .gte('created_at', monthStart.toIso8601String());

      final List<Map<String, dynamic>> monthlyQuizzes =
          List<Map<String, dynamic>>.from(monthlyQuizzesResponse);
      double monthlyTotal = 0;
      for (var quiz in monthlyQuizzes) {
        monthlyTotal += (quiz['score'] as num).toDouble();
      }

      // Load achievements
      final achievementsResponse =
          await _supabase.from('Achievement').select().order('created_at');

      final List<Map<String, dynamic>> achievements =
          List<Map<String, dynamic>>.from(achievementsResponse);

      if (mounted) {
        setState(() {
          _username = profileData['username'] ?? 'App User';
          _score = (profileData['score'] ?? 0).toDouble();
          _currentLevel = profileData['current_level'] ?? 'Beginner';
          _balance = (profileData['balance'] ?? 0).toDouble();
          _totalQuizzes = completedQuizCount;
          _monthlyAverage =
              monthlyQuizzes.isEmpty ? 0 : monthlyTotal / monthlyQuizzes.length;
          _achievements = achievements;
          _isLoading = false;
          _usernameController.text = _username;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $error')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateUsername() async {
    if (_usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase
          .from('profile')
          .update({'username': _usernameController.text}).eq('id', userId);

      if (mounted) {
        setState(() => _username = _usernameController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username updated successfully!')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating username: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Card(
              color: Colors.grey[500],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        _username.isNotEmpty ? _username[0].toUpperCase() : 'U',
                        style:
                            const TextStyle(fontSize: 32, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _updateUsername,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats Section
            Card(
              color: Colors.grey[500],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildStatTile('Current Level', _currentLevel),
                    _buildStatTile('Total Score', _score.toStringAsFixed(0)),
                    _buildStatTile(
                        'Stars Balance', '⭐ ${_balance.toStringAsFixed(0)}'),
                    _buildStatTile(
                        'Completed Quizzes', _totalQuizzes.toString()),
                    _buildStatTile(
                      'Monthly Average Score',
                      _monthlyAverage.toStringAsFixed(1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Achievements Section
            Card(
              color: Colors.grey[500],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Achievements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _achievements.length,
                      itemBuilder: (context, index) {
                        final achievement = _achievements[index];
                        return Tooltip(
                          message: achievement['achievement_name'] ?? '',
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                achievement['img_url'],
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                      Icons.emoji_events_outlined);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
