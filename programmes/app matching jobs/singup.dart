import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
import 'loginScreen.dart';
import '../services/session_service.dart';
// import '../services/database_service.dart';
import '../models/user_model.dart';
import '../services/photo_service.dart';
import '../widgets/profile_photo_widget.dart';
import 'dashboard.dart';
import '../services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _dateOfBirth = TextEditingController();
  final TextEditingController _jobTitle = TextEditingController();
  final TextEditingController _companyName = TextEditingController();

  String? _selectedCountry;
  String? _selectedRole;
  bool _isLoading = false;

  final List<String> _countries = [
    'Tunisia',
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'Netherlands',
    'Sweden',
    'Australia',
    'India',
    'Japan',
    'Spain',
    'Italy',
    'Brazil',
    'South Africa',
    'United Arab Emirates',
    'Egypt',
    'Mexico',
    'Turkey',
    'Nigeria',
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country')),
      );
      return;
    }
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your role')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if backend is available
      final isHealthy = await ApiService.checkApiHealth();
      if (!isHealthy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Backend not reachable. Please start your Laravel server and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Prepare registration data
      final userData = {
        'name': _fullName.text,
        'email': _email.text,
        'password': _password.text,
        'phone_number': _phone.text,
        'date_of_birth': _dateOfBirth.text,
        'country': _selectedCountry!,
        'role': _selectedRole!,
      };

      // Add role-specific data
      if (_selectedRole == 'candidate') {
        userData['job_title'] = _jobTitle.text;
      } else if (_selectedRole == 'employer') {
        userData['company_name'] = _companyName.text;
      }

      // Register via Laravel API
      final response = await ApiService.register(userData);

      // The ApiService already handles saving the token and user data
      if (response['token'] != null) {
        // Get user data from session to pass to Dashboard
        final user = await SessionService.getCurrentUser();
        if (user != null) {
          // Navigate to dashboard
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
        }
      } else {
        throw Exception('Registration failed');
      }
    } catch (e) {
      print('Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _dateOfBirth.dispose();
    _jobTitle.dispose();
    _companyName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color cream = Color(0xFFF5EFE6);
    const Color darkCoffee = Color(0xFF4B2E2A);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/snow.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cream.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    // App Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B2E2A),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'CV12',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Photo Upload
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Profile Photo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F2F2F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          EditableProfilePhotoWidget(
                            userId:
                                'temp_${DateTime.now().millisecondsSinceEpoch}',
                            size: 80,
                            showBorder: true,
                            borderColor: const Color(0xFF4B2E2A),
                            borderWidth: 2,
                            onPhotoChanged: (String photo) {
                              // Store the photo temporarily for registration
                              // You can implement this logic as needed
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload your profile photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Create your professional profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your details and select your role.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Role Selection
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              items: const [
                                DropdownMenuItem(
                                    value: 'candidate',
                                    child: Text('Candidate')),
                                DropdownMenuItem(
                                    value: 'employer', child: Text('Employer')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value),
                              decoration: const InputDecoration(
                                labelText: 'Select Your Role',
                                border: InputBorder.none,
                              ),
                              validator: (value) =>
                                  value == null ? 'Please select a role' : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _fullName,
                              label: 'Full Name',
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter full name'
                                  : null),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _email,
                              label: 'Email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Enter email';
                                final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(v))
                                  return 'Enter valid email';
                                return null;
                              }),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _password,
                              label: 'Password',
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Password >= 6 chars'
                                  : null),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _phone,
                              label: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter phone number'
                                  : null),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _dateOfBirth,
                              label: 'Date of Birth (YYYY-MM-DD)',
                              keyboardType: TextInputType.datetime,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Enter date of birth'
                                  : null),
                          const SizedBox(height: 16),

                          // Conditional fields based on role
                          if (_selectedRole == 'candidate') ...[
                            _buildTextField(
                                controller: _jobTitle,
                                label: 'Job Title',
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter job title'
                                    : null),
                            const SizedBox(height: 16),
                          ],

                          if (_selectedRole == 'employer') ...[
                            _buildTextField(
                                controller: _companyName,
                                label: 'Company Name',
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter company name'
                                    : null),
                            const SizedBox(height: 16),
                          ],

                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            items: _countries
                                .map((c) =>
                                    DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCountry = v),
                            decoration: InputDecoration(
                              labelText: 'Country',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(28),
                                  borderSide: BorderSide.none),
                            ),
                            validator: (v) =>
                                v == null ? 'Select country' : null,
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkCoffee,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 6,
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account?'),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const LoginScreen()),
                                  );
                                },
                                child: const Text('Login',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: darkCoffee,
        title: const Text('Sign Up'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none),
      ),
    );
  }
}
