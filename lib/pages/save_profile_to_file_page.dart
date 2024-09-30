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
  String? _publicUrl; // Store the public URL from Supabase

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
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'profile_data_${user.id}_$timestamp.txt';
      final file = File('${directory.path}/$uniqueFileName');
      await file.writeAsString(profileData);

      // Step 4: Upload the file to Supabase storage
      final storagePath = await _supabaseClient.storage
          .from('profile-bucket') // Supabase bucket name
          .upload('profiles/$uniqueFileName', file);

      // Step 5: Get the public URL for the uploaded file
      final publicUrl = _supabaseClient.storage
          .from('profile-bucket')
          .getPublicUrl('profiles/$uniqueFileName');

      setState(() {
        _publicUrl = publicUrl; // Set the public URL after successful upload
        print('Public URL: $_publicUrl'); // Debugging print
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved to Supabase storage!')),
      );
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

  // Method to share the public URL
  Future<void> _shareFile() async {
    if (_publicUrl != null) {
      print('Sharing URL: $_publicUrl'); // Debugging print
      await Share.share(' $_publicUrl');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file available to share.')),
      );
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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _saveProfileToFile,
                    child: Text('Save Profile'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _shareFile,
                    child: Text('Share Profile Link'),
                  ),
                ],
              ),
      ),
    );
  }
}
