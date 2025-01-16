import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPages extends StatefulWidget {
  const SignupPages({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignupPagesState createState() => _SignupPagesState();
}

class _SignupPagesState extends State<SignupPages> {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  final _loginController = TextEditingController(); // Added login controller
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _termsAccepted = false;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _loginController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validate inputs
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _loginController.text.trim(),
          'full_name': _nameController.text.trim(),
          'phone': '+234${_phoneController.text.trim()}',
        },
      );

      if (mounted) {
        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully signed up! Please check your email.'),
            ),
          );
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } on AuthException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter an email');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError('Please enter a valid email');
      return false;
    }

    if (_loginController.text.trim().isEmpty) {
      _showError('Please enter a username');
      return false;
    }

    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your full name');
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter a phone number');
      return false;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showError('Please enter a password');
      return false;
    }

    if (_passwordController.text.trim().length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }

    if (!_termsAccepted) {
      _showError('Please accept the terms and conditions');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A9D8F),
              Color(0xFF264653),
            ],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildFirstPage(),
              _buildSecondPage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          SizedBox(height: 20),
          Text(
            'Personal information',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 20),
          Text(
            'Sign up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _loginController,
            label: 'Username',
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
          ),
          SizedBox(height: 15),
          _buildPhoneField(),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Text(
                  'Sign in',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate first page inputs before moving to next page
                  if (_emailController.text.trim().isNotEmpty &&
                      _loginController.text.trim().isNotEmpty &&
                      _nameController.text.trim().isNotEmpty &&
                      _phoneController.text.trim().isNotEmpty) {
                    _pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _showError('Please fill in all fields');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  'Next step',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildSecondPage() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(),
          SizedBox(height: 20),
          Text(
            'Personal information',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 20),
          Text(
            'Sign up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _passwordController,
            label: 'Create a password',
            isPassword: true,
            passwordVisible: _passwordVisible,
            onPasswordVisibilityToggle: () {
              setState(() {
                _passwordVisible = !_passwordVisible;
              });
            },
          ),
          SizedBox(height: 15),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Repeat password',
            isPassword: true,
            passwordVisible: _confirmPasswordVisible, // Use separate state
            onPasswordVisibilityToggle: () {
              setState(() {
                _confirmPasswordVisible =
                    !_confirmPasswordVisible; // Toggle separate state
              });
            },
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
                fillColor: MaterialStateProperty.all(Colors.orange),
              ),
              Text(
                'I agree with ',
                style: TextStyle(color: Colors.white),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement Terms and Privacy dialog or navigation
                },
                child: Text(
                  'Terms and Privacy',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Text(
                  'Previous step',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create an account',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Icon(Icons.science, color: Colors.orange, size: 30),
        SizedBox(width: 8),
        Text(
          'Phynix',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool passwordVisible = false,
    VoidCallback? onPasswordVisibilityToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !passwordVisible,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: onPasswordVisibilityToggle,
              )
            : null,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: TextField(
            decoration: InputDecoration(
              labelText: '+234',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone number',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange),
              ),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
