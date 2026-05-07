import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dashboard.dart';
import '../services/session_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_photo_widget.dart';

class CandidatePage extends StatefulWidget {
  const CandidatePage({Key? key}) : super(key: key);

  @override
  State<CandidatePage> createState() => _CandidatePageState();
}

class _CandidatePageState extends State<CandidatePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedCountry;
  PlatformFile? _cvFile;
  File? _cvFileFile;
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  String? _currentCvPath;
  List<String> _skills = [];

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

  final List<String> _availableSkills = [
    'Flutter',
    'Dart',
    'React',
    'JavaScript',
    'Python',
    'Java',
    'C++',
    'C#',
    'Node.js',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'Firebase',
    'AWS',
    'Docker',
    'Git',
    'REST APIs',
    'GraphQL',
    'UI/UX Design',
    'Agile',
    'Scrum',
    'Project Management',
    'Data Analysis',
    'Machine Learning',
    'DevOps'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await SessionService.getUserSession();
      if (user != null && user is Candidate) {
        setState(() {
          _fullNameController.text = user.name;
          _emailController.text = user.email;
          _jobTitleController.text = user.jobTitle ?? '';
          _selectedCountry = user.country;
          _bioController.text = user.profileSummary ?? '';
          _skills = List.from(user.skills);
          _currentCvPath = user.cvPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _pickCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _cvFile = result.files.first;
          _cvFileFile = File(_cvFile!.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_skills.contains(skill)) {
        _skills.remove(skill);
      } else {
        _skills.add(skill);
      }
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user to preserve existing data
      final currentUser = await SessionService.getUserSession();
      if (currentUser == null) {
        throw Exception('No current user found');
      }

      // Create updated candidate profile
      final updatedCandidate = Candidate(
        id: currentUser.id,
        name: _fullNameController.text,
        email: _emailController.text,
        role: 'candidate',
        phoneNumber: currentUser.phoneNumber,
        dateOfBirth: currentUser.dateOfBirth,
        country: _selectedCountry!,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
        jobTitle: _jobTitleController.text,
        skills: _skills,
        cvPath: _cvFile?.path ?? _currentCvPath,
        profileSummary: _bioController.text,
      );

      // Save updated profile
      await SessionService.saveUserSession(updatedCandidate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // Navigate back to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(
              userRole: 'candidate',
              userId: updatedCandidate.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _jobTitleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2E2A),
        title: const Text('Candidate Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    EditableProfilePhotoWidget(
                      userId: _fullNameController.text.isNotEmpty
                          ? _fullNameController.text
                          : 'temp_${DateTime.now().millisecondsSinceEpoch}',
                      size: 100,
                      showBorder: true,
                      borderColor: const Color(0xFF4B2E2A),
                      borderWidth: 3,
                      onPhotoChanged: (String photo) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile photo updated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Update Your Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F2F2F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keep your information up to date',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information
              _buildSection(
                title: 'Personal Information',
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    validator: (value) => value?.isEmpty == true
                        ? 'Please enter your full name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value?.isEmpty == true)
                        return 'Please enter your email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _jobTitleController,
                    label: 'Job Title',
                    validator: (value) => value?.isEmpty == true
                        ? 'Please enter your job title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    value: _selectedCountry,
                    items: _countries,
                    label: 'Country',
                    onChanged: (value) =>
                        setState(() => _selectedCountry = value),
                    validator: (value) =>
                        value == null ? 'Please select your country' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bio
              _buildSection(
                title: 'Bio',
                children: [
                  _buildTextField(
                    controller: _bioController,
                    label: 'Tell us about yourself',
                    maxLines: 4,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Please enter your bio' : null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Skills
              _buildSection(
                title: 'Skills',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSkills.map((skill) {
                      final isSelected = _skills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (_) => _toggleSkill(skill),
                        selectedColor:
                            const Color(0xFF4B2E2A).withValues(alpha: 0.2),
                        checkmarkColor: const Color(0xFF4B2E2A),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // CV Upload
              _buildSection(
                title: 'CV Upload',
                children: [
                  GestureDetector(
                    onTap: _pickCV,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cvFile != null
                                ? _cvFile!.name
                                : 'Click to upload CV (PDF, DOC, DOCX)',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B2E2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F2F2F),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B2E2A)),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4B2E2A)),
        ),
      ),
    );
  }
}
