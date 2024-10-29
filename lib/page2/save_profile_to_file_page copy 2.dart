import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaveProfileToFilePage extends StatefulWidget {
  @override
  _SaveProfileToFilePageState createState() => _SaveProfileToFilePageState();
}

class _SaveProfileToFilePageState extends State<SaveProfileToFilePage> {
  final _supabaseClient = Supabase.instance.client;
  bool _isLoading = false;
  String? _filePath; // Path of the saved file

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
II.  Nama  : ${response['name'] ?? ''}
No. KTP   : ${response['nik'] ?? ''}
No. HP    : ${response['phone'] ?? ''}
Alamat    : ………………….., untuk sementara berada di Jakarta, dalam hal ini bertindak untuk dan atas nama diri sendiri, untuk selanjutnya disebut :
      ''';

      // Step 3: Write plain text data to a file
      final directory = await getApplicationDocumentsDirectory();

      // Create a unique file name using the user ID and current timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'profile_data_${user.id}_$timestamp.txt';

      final file = File('${directory.path}/$uniqueFileName');
      await file.writeAsString(profileData);

      // Save the file path for sharing
      _filePath = file.path;

      // Step 4: Upload the file to Supabase storage with a unique name
      final storageResponse = await _supabaseClient.storage
          .from('profile-bucket') // Your Supabase bucket name
          .upload('/$uniqueFileName', file);

      // Uncomment this section to show a success message after uploading
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

  Future<void> _shareFile() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('File not found. Please save the profile first.')),
      );
      return;
    }

    // Share the file for printing or other uses
    await Share.share('Here is your profile data: $_filePath');
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveProfileToFile,
                    child: Text('Save Profile'),
                  ),
                  if (_filePath !=
                      null) // Show share button only if file exists
                    ElevatedButton(
                      onPressed: _shareFile,
                      child: Text('Share Profile File'),
                    ),
                ],
              ),
      ),
    );
  }
}
