import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({bool fromCamera = false}) async {
    try {
      FilePickerResult? result;

      if (fromCamera) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path!);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Convert image to base64 string for storage
  Future<String?> imageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);
      return base64String;
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  /// Save profile photo to local storage
  Future<bool> saveProfilePhoto(String userId, String base64Image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_$userId', base64Image);
      return true;
    } catch (e) {
      print('Error saving profile photo: $e');
      return false;
    }
  }

  /// Get profile photo from local storage
  Future<String?> getProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile_photo_$userId');
    } catch (e) {
      print('Error getting profile photo: $e');
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_photo_$userId');
      return true;
    } catch (e) {
      print('Error deleting profile photo: $e');
      return false;
    }
  }

  /// Check if user has a profile photo
  Future<bool> hasProfilePhoto(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('profile_photo_$userId');
    } catch (e) {
      print('Error checking profile photo: $e');
      return false;
    }
  }
}
