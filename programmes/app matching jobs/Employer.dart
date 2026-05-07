import 'package:flutter/material.dart';
import 'dashboard.dart';
import '../services/session_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../widgets/profile_photo_widget.dart';

class EmployerPage extends StatefulWidget {
  const EmployerPage({Key? key}) : super(key: key);

  @override
  State<EmployerPage> createState() => _EmployerPageState();
}

class _EmployerPageState extends State<EmployerPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _jobDescriptionController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _salaryController = TextEditingController();

  List<JobOffer> jobOffers = [];
  bool _isLoading = false;
  bool _isLoadingOffers = true;
  List<String> _selectedSkills = [];

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
    _loadJobOffers();
  }

  Future<void> _loadJobOffers() async {
    try {
      final user = await SessionService.getUserSession();
      if (user != null && user is Employer) {
        // Load job offers from database instead of user object
        final allJobOffers = await DatabaseService.getAllJobOffers();
        // Filter job offers for this employer (you might need to add employerId to JobOffer model)
        setState(() {
          jobOffers = allJobOffers;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading job offers: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingOffers = false;
      });
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  Future<void> _submitJobOffer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one required skill')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get current user
      final user = await SessionService.getUserSession();
      if (user == null) {
        throw Exception('No current user found');
      }

      // Create new job offer
      final newJobOffer = JobOffer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _jobTitleController.text,
        description: _jobDescriptionController.text,
        skillsRequired: _selectedSkills,
        location: _locationController.text,
        salary:
            _salaryController.text.isNotEmpty ? _salaryController.text : null,
        createdAt: DateTime.now(),
      );

      // Save job offer to database
      await DatabaseService.saveJobOffer(newJobOffer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job offer posted successfully!')),
        );

        // Clear form
        _jobTitleController.clear();
        _jobDescriptionController.clear();
        _locationController.clear();
        _salaryController.clear();
        setState(() {
          _selectedSkills.clear();
        });

        // Reload job offers
        await _loadJobOffers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting job offer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _deleteJobOffer(String jobId) async {
    try {
      // Delete from database
      await DatabaseService.deleteJobOffer(jobId);

      // Reload job offers
      await _loadJobOffers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job offer deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting job offer: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _jobDescriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOffers) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B2E2A),
        title: const Text('Employer Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Photo Section
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
                    userId: 'employer_${DateTime.now().millisecondsSinceEpoch}',
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
                    'Employer Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F2F2F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your company profile and job offers',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Post Job Offer Section
            _buildSection(
              title: 'Post New Job Offer',
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _jobTitleController,
                        label: 'Job Title',
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter job title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _jobDescriptionController,
                        label: 'Job Description',
                        maxLines: 4,
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter job description'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _locationController,
                        label: 'Location',
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter location'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _salaryController,
                        label: 'Salary Range (e.g., \$50,000 - \$80,000)',
                        validator: (value) => value?.isEmpty == true
                            ? 'Please enter salary range'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Required Skills:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F2F2F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSkills.map((skill) {
                          final isSelected = _selectedSkills.contains(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: isSelected,
                            onSelected: (_) => _toggleSkill(skill),
                            selectedColor:
                                const Color(0xFF4B2E2A).withValues(alpha: 0.1),
                            checkmarkColor: const Color(0xFF4B2E2A),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitJobOffer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B2E2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Post Job Offer',
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
              ],
            ),

            const SizedBox(height: 24),

            // My Job Offers Section
            _buildSection(
              title: 'My Job Offers (${jobOffers.length})',
              children: jobOffers.isEmpty
                  ? [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No job offers posted yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ]
                  : jobOffers
                      .map((jobOffer) => _buildJobOfferCard(jobOffer))
                      .toList(),
            ),
          ],
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

  Widget _buildJobOfferCard(JobOffer jobOffer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jobOffer.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F2F2F),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteJobOffer(jobOffer.id),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            jobOffer.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                jobOffer.location,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              if (jobOffer.salary != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  jobOffer.salary!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: jobOffer.skillsRequired
                .take(3)
                .map((skill) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4B2E2A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B2E2A),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
