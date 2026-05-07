import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'singup.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String animationLink = 'assets/login.riv';
  SMIInput<bool>? isChecking;
  SMIInput<bool>? isHandsUp;
  SMIInput<bool>? trigSuccess;
  SMIInput<bool>? trigFail;
  late StateMachineController? stateMachineController;
  bool _isLoading = false;

  DateTime _safeParseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.now();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    stateMachineController?.dispose();
    super.dispose();
  }

  void _triggerSuccessFlow() {
    isChecking?.change(false);
    isHandsUp?.change(false);
    trigFail?.change(false);
    trigSuccess?.change(true);
  }

  void _triggerFailFlow() {
    isChecking?.change(false);
    isHandsUp?.change(false);
    trigSuccess?.change(false);
    trigFail?.change(true);
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) {
      _triggerFailFlow();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new ApiService for login
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      // The ApiService already handles saving the token and user data
      if (response['token'] != null) {
        _triggerSuccessFlow();
        
        // Get user data from session to pass to Dashboard
        final user = await SessionService.getCurrentUser();
        if (user != null) {
          // Navigate to dashboard after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Dashboard(
                    userRole: user.role,
                    userId: user.id,
                  ),
                ),
              );
            }
          });
        }
      } else {
        _triggerFailFlow();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Login error: $e');
      _triggerFailFlow();
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color icy = Color(0xFFD4F1F9);
    const Color darkCoffee = Color(0xFF4B2E2A);
    const Color cream = Color(0xFFF5EFE6);

    return Scaffold(
      backgroundColor: icy,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE8F7FB), Color(0xFFB8D8E6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cream,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                                                     // No logo - blank space as requested
                          const SizedBox(height: 20),

                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F2F2F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Login to continue',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 250,
                            child: RiveAnimation.asset(
                              animationLink,
                              fit: BoxFit.contain,
                              stateMachines: const ['Login Machine'],
                              onInit: (artBoard) {
                                stateMachineController =
                                    StateMachineController.fromArtboard(
                                        artBoard, 'Login Machine');
                                if (stateMachineController == null) return;
                                artBoard.addController(stateMachineController!);
                                isChecking = stateMachineController
                                    ?.findInput('isChecking');
                                isHandsUp = stateMachineController
                                    ?.findInput('isHandsUp');
                                trigSuccess = stateMachineController
                                    ?.findInput('trigSuccess');
                                trigFail = stateMachineController
                                    ?.findInput('trigFail');
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildInputField(
                                  controller: _emailController,
                                  label: 'Email',
                                  onChanged: (_) {
                                    isHandsUp?.change(false);
                                    isChecking?.change(true);
                                  },
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Enter email';
                                    final emailRegex =
                                        RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(v))
                                      return 'Enter valid email';
                                    return null;
                                  },
                                  prefix: Icons.email,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  obscure: true,
                                  onChanged: (_) {
                                    isChecking?.change(false);
                                    isHandsUp?.change(true);
                                  },
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Enter password'
                                      : null,
                                  prefix: Icons.lock,
                                ),
                                const SizedBox(height: 28),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(30),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF6B4F3C),
                                          Color(0xFFBC8F5F)
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              darkCoffee.withValues(alpha: 0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white)
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    // Add forgot password functionality
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Color(0xFF5A4F3F)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2C1A),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required void Function(String) onChanged,
    required String? Function(String?) validator,
    bool obscure = false,
    IconData? prefix,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: prefix != null
            ? Icon(prefix, color: const Color(0xFF5A4F3F))
            : null,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}
