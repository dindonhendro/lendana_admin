import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart'; // for basename

class CardService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = '$userId/avatar/${basename(imageFile.path)}';
      final response = await _supabaseClient.storage
          .from('profiles') // Ensure the bucket name is correct
          .upload(fileName, imageFile);

      return _supabaseClient.storage.from('profiles').getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadIdCardImage(File imageFile, String userId) async {
    try {
      final fileName = '$userId/id_card/${basename(imageFile.path)}';
      final response = await _supabaseClient.storage
          .from('id_cards') // Ensure the bucket name is correct
          .upload(fileName, imageFile);

      return _supabaseClient.storage.from('id_cards').getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading ID card image: $e');
      return null;
    }
  }

  Future<void> updateProfile(
      String id, String avatarUrl, String idCardUrl) async {
    try {
      await _supabaseClient.from('profiles').update({
        'avatar_url': avatarUrl,
        'id_card_url': idCardUrl,
      }).eq('id', id); // Using 'id' to update the profile
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  Future<String?> getProfileImageUrl(String id) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('avatar_url')
          .eq('id', id) // Using 'id' to get the avatar URL
          .single();

      return response['avatar_url'] as String?;
    } catch (e) {
      print('Error fetching profile image: $e');
      return null;
    }
  }

  Future<String?> getIdCardUrl(String id) async {
    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('id_card_url')
          .eq('id', id) // Using 'id' to get the ID card URL
          .single();

      return response['id_card_url'] as String?;
    } catch (e) {
      print('Error fetching ID card URL: $e');
      return null;
    }
  }
}
