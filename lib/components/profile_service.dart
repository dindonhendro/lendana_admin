import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart'; // for basename

class ProfileService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Upload the image to the 'profiles' bucket, named by the user ID
      final fileName = '$userId/${basename(imageFile.path)}';
      await _supabaseClient.storage
          .from('profiles')
          .upload(fileName, imageFile);

      // Get the public URL of the uploaded image
      final String imageUrl =
          _supabaseClient.storage.from('profiles').getPublicUrl(fileName);

      // Return the image URL
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> updateProfile(String userId, String avatarUrl) async {
    try {
      // Update the user's avatar URL in the 'profiles' table
      await _supabaseClient
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  Future<String?> getProfileImageUrl(String userId) async {
    try {
      // Get the user's avatar URL from the 'profiles' table
      final response = await _supabaseClient
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      return response['avatar_url'];
    } catch (e) {
      print('Error fetching profile image: $e');
      return null;
    }
  }
}
