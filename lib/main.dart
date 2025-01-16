import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phynix/root/badge.dart';
import 'package:phynix/root/history.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'root/dashboard.dart';
import 'const/color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp()); // Run app immediately with splash screen

  // Initialize in background
  await Future.wait([
    dotenv.load(fileName: ".env"),
    Future.delayed(const Duration(seconds: 3)), // Minimum splash screen time
  ]);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phynix',
      theme: ThemeData(
        primaryColor: myPrimaryColor,
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.orange,
          secondary: const Color(0xFF264653),
        ),
      ),
      home: const InitializationWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPages(),
        '/home': (context) => const PhynixDashboard(),
        '/quiz-history': (context) => QuizHistoryPage(),
        '/badges': (context) => BadgesPage(),
      },
    );
  }
}

class InitializationWrapper extends StatefulWidget {
  const InitializationWrapper({super.key});

  @override
  State<InitializationWrapper> createState() => _InitializationWrapperState();
}

class _InitializationWrapperState extends State<InitializationWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for Supabase initialization
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    return AuthWrapper();
  }
}

// Add this class before MyApp
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: myPrimaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _controller,
                child: Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Phynix',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  User? _user;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    _startSessionCheck();
  }

  Future<void> _checkAuthStatus() async {
    // Add delay to show splash screen
    await Future.delayed(const Duration(seconds: 3));

    final supabase = Supabase.instance.client;

    setState(() {
      _user = supabase.auth.currentUser;
      _isLoading = false;
    });
  }

  void _startSessionCheck() {
    final supabase = Supabase.instance.client;
    // Check session every 5 minutes
    Timer.periodic(Duration(minutes: 5), (timer) async {
      final session = supabase.auth.currentSession;
      print(session);
      if (session != null) {
        final response = await supabase.auth.refreshSession();
        if (response.user == null) {
          _signOutUser();
        }
      }
    });
  }

  void _signOutUser() {
    final supabase = Supabase.instance.client;
    supabase.auth.signOut();
    // Navigate to login screen or show a dialog
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen(); // Show splash screen instead of loading indicator
    }

    return _user != null ? const PhynixDashboard() : const LoginPage();
  }
}
