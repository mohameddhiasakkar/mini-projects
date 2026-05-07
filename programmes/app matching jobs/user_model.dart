class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? country;
  final String? profilePhoto; // Add profile photo field
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.dateOfBirth,
    this.country,
    this.profilePhoto, // Add profile photo parameter
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth,
      'country': country,
      'profile_photo': profilePhoto, // Add profile photo to JSON
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle null values and provide defaults for required fields
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('User ID is required and cannot be null or empty');
    }

    final name = json['name'] ?? json['full_name'] ?? '';
    if (name.isEmpty) {
      throw Exception('User name is required and cannot be empty');
    }

    final email = json['email'] ?? '';
    if (email.isEmpty) {
      throw Exception('User email is required and cannot be empty');
    }

    final role = json['role'] ?? '';
    if (role.isEmpty) {
      throw Exception('User role is required and cannot be empty');
    }

    // Safely parse dates with fallbacks
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'] ?? '');
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(json['updated_at'] ?? '');
    } catch (e) {
      updatedAt = DateTime.now();
    }

    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'],
      country: json['country'],
      profilePhoto: json['profile_photo'],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class Candidate extends User {
  final String? jobTitle;
  final List<String> skills;
  final String? cvPath;
  final String? profileSummary;

  Candidate({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phoneNumber,
    super.dateOfBirth,
    super.country,
    super.profilePhoto, // Add profile photo to Candidate
    required super.createdAt,
    required super.updatedAt,
    this.jobTitle,
    this.skills = const [],
    this.cvPath,
    this.profileSummary,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    // Handle null values and provide defaults for required fields
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Candidate ID is required and cannot be null or empty');
    }

    final name = json['name'] ?? json['full_name'] ?? '';
    if (name.isEmpty) {
      throw Exception('Candidate name is required and cannot be empty');
    }

    final email = json['email'] ?? '';
    if (email.isEmpty) {
      throw Exception('Candidate email is required and cannot be empty');
    }

    final role = json['role'] ?? 'candidate';

    // Safely parse dates with fallbacks
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'] ?? '');
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(json['updated_at'] ?? '');
    } catch (e) {
      updatedAt = DateTime.now();
    }

    return Candidate(
      id: id,
      name: name,
      email: email,
      role: role,
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'],
      country: json['country'],
      profilePhoto: json['profile_photo'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      jobTitle: json['job_title'],
      skills: List<String>.from(json['skills'] ?? []),
      cvPath: json['cv_path'],
      profileSummary: json['profile_summary'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'job_title': jobTitle,
      'skills': skills,
      'cv_path': cvPath,
      'profile_summary': profileSummary,
    };
  }
}

class Employer extends User {
  final String? companyName;
  final String? companyDescription;
  final int jobOffersCount;
  final List<Map<String, dynamic>> recentJobOffers;

  Employer({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.phoneNumber,
    super.dateOfBirth,
    super.country,
    super.profilePhoto, // Add profile photo to Employer
    required super.createdAt,
    required super.updatedAt,
    this.companyName,
    this.companyDescription,
    this.jobOffersCount = 0,
    this.recentJobOffers = const [],
  });

  factory Employer.fromJson(Map<String, dynamic> json) {
    // Handle null values and provide defaults for required fields
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw Exception('Employer ID is required and cannot be null or empty');
    }

    final name = json['name'] ?? json['full_name'] ?? '';
    if (name.isEmpty) {
      throw Exception('Employer name is required and cannot be empty');
    }

    final email = json['email'] ?? '';
    if (email.isEmpty) {
      throw Exception('Employer email is required and cannot be empty');
    }

    final role = json['role'] ?? 'employer';

    // Safely parse dates with fallbacks
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at'] ?? '');
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime updatedAt;
    try {
      updatedAt = DateTime.parse(json['updated_at'] ?? '');
    } catch (e) {
      updatedAt = DateTime.now();
    }

    return Employer(
      id: id,
      name: name,
      email: email,
      role: role,
      phoneNumber: json['phone_number'],
      dateOfBirth: json['date_of_birth'],
      country: json['country'],
      profilePhoto: json['profile_photo'],
      createdAt: createdAt,
      updatedAt: updatedAt,
      companyName: json['company_name'],
      companyDescription: json['company_description'],
      jobOffersCount: json['job_offers_count'] ?? 0,
      recentJobOffers:
          List<Map<String, dynamic>>.from(json['recent_job_offers'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'company_name': companyName,
      'company_description': companyDescription,
      'job_offers_count': jobOffersCount,
      'recent_job_offers': recentJobOffers,
    };
  }
}

class JobOffer {
  final String id;
  final String title;
  final String description;
  final List<String> skillsRequired;
  final String location;
  final String? salary;
  final DateTime createdAt;

  JobOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.skillsRequired,
    required this.location,
    this.salary,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'skillsRequired': skillsRequired,
      'location': location,
      'salary': salary,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JobOffer.fromJson(Map<String, dynamic> json) {
    return JobOffer(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      skillsRequired: List<String>.from(json['skills_required'] ?? []),
      location: json['location'] ?? '',
      salary: json['salary'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class Match {
  final String id;
  final String candidateId;
  final String employerId;
  final String? jobOfferId;
  final DateTime matchedAt;
  final bool isActive;
  final bool isSuperLike;
  final String? candidateName; // Add candidate name
  final String? employerName; // Add employer name

  Match({
    required this.id,
    required this.candidateId,
    required this.employerId,
    this.jobOfferId,
    required this.matchedAt,
    this.isActive = true,
    this.isSuperLike = false,
    this.candidateName, // Add candidate name parameter
    this.employerName, // Add employer name parameter
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'candidateId': candidateId,
      'employerId': employerId,
      'jobOfferId': jobOfferId,
      'matchedAt': matchedAt.toIso8601String(),
      'isActive': isActive,
      'isSuperLike': isSuperLike,
      'candidateName': candidateName, // Add candidate name to JSON
      'employerName': employerName, // Add employer name to JSON
    };
  }

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'].toString(),
      candidateId: json['candidate_id'] ?? json['candidateId'] ?? '',
      employerId: json['employer_id'] ?? json['employerId'] ?? '',
      jobOfferId: json['job_offer_id'] ?? json['jobOfferId'],
      matchedAt: DateTime.parse(json['matched_at'] ??
          json['matchedAt'] ??
          DateTime.now().toIso8601String()),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      isSuperLike: json['is_super_like'] ?? json['isSuperLike'] ?? false,
      candidateName: json['candidate_name'] ??
          json['candidateName'], // Parse candidate name from JSON
      employerName: json['employer_name'] ??
          json['employerName'], // Parse employer name from JSON
    );
  }

  Match copyWith({
    String? id,
    String? candidateId,
    String? employerId,
    String? jobOfferId,
    DateTime? matchedAt,
    bool? isActive,
    bool? isSuperLike,
    String? candidateName, // Add candidate name to copyWith
    String? employerName, // Add employer name to copyWith
  }) {
    return Match(
      id: id ?? this.id,
      candidateId: candidateId ?? this.candidateId,
      employerId: employerId ?? this.employerId,
      jobOfferId: jobOfferId ?? this.jobOfferId,
      matchedAt: matchedAt ?? this.matchedAt,
      isActive: isActive ?? this.isActive,
      isSuperLike: isSuperLike ?? this.isSuperLike,
      candidateName: candidateName ?? this.candidateName, // Copy candidate name
      employerName: employerName ?? this.employerName, // Copy employer name
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String senderName;
  final String senderRole; // 'candidate' or 'employer'

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    required this.senderName,
    required this.senderRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'sender_name': senderName,
      'sender_role': senderRole,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      receiverId: json['receiver_id'] ?? json['receiverId'] ?? '',
      content: json['content'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      senderName: json['sender_name'] ?? json['senderName'] ?? '',
      senderRole: json['sender_role'] ?? json['senderRole'] ?? '',
    );
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? senderName,
    String? senderRole,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
    );
  }

  // Helper method to convert short role to readable name
  String get displayRole {
    switch (senderRole.toLowerCase()) {
      case 'u':
        return 'User';
      case 'e':
        return 'Employer';
      case 'a':
        return 'AI';
      case 'c':
        return 'Candidate';
      default:
        return senderRole;
    }
  }

  // Helper method to check if user is employer
}
