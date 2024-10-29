import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaveProfileToFilePage extends StatefulWidget {
  @override
  _SaveProfileToFilePageState createState() => _SaveProfileToFilePageState();
}

class _SaveProfileToFilePageState extends State<SaveProfileToFilePage> {
  final _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;

  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  Future<void> _saveProfileToFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Fetch dynamic data from Supabase
      final user = _supabaseClient.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User is not logged in.')),
        );
        return;
      }

      final response = await _supabaseClient
          .from('users')
          .select('name, phone, nik')
          .eq('user_id', user.id)
          .single();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user data found.')),
        );
        return;
      }

      // Step 2: Convert fetched data to plain text format
      final profileData = '''

II.	Nama	: ${response['name'] ?? ''}
No. KTP 	: ${response['nik'] ?? ''}
No. HP	: ${response['phone'] ?? ''}
Alamat	: ………………….., untuk sementara berada di Jakarta, dalam hal ini bertindak untuk dan atas nama diri sendiri, untuk selanjutnya disebut :

      ''';

      // Step 3: Write plain text data to a file
      final directory = await getApplicationDocumentsDirectory();

      // Create a unique file name using the user ID and current timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'profile_data_${user.id}_$timestamp.txt';

      final file = File('${directory.path}/$uniqueFileName');
      await file.writeAsString(profileData);

      // Step 4: Upload the file to Supabase storage with a unique name
      final storageResponse = await _supabaseClient.storage
          .from('profile-bucket') // Your Supabase bucket name
          .upload('/$uniqueFileName', file);

      // if (storageResponse.error == null) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Profile saved to Supabase storage!')),
      //   );
      // } else {
      //   throw Exception(storageResponse.error!.message);
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Save Profile to File'),
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _saveProfileToFile,
                child: Text('Save Profile'),
              ),
      ),
    );
  }
}
