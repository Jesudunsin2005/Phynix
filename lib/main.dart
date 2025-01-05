import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';
import 'root/dashboard.dart';
import 'const/color.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
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
      home: AuthWrapper(), // Use AuthWrapper instead of initialRoute
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPages(),
        '/home': (context) => const PhynixDashboard(),
      },
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _user != null ? const PhynixDashboard() : const LoginPage();
  }
}
