import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/card_service.dart';

class CardPage extends StatefulWidget {
  @override
  _CardPageState createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {
  final _supabaseClient = Supabase.instance.client;
  final CardService _cardService = CardService();
  String? _avatarUrl;
  String? _idCardUrl;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    // _fetchUserData();
    _loadProfileImage();
    _loadIdCardImage();
  }

  Future<void> _loadProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    final avatarUrl = await _cardService.getProfileImageUrl(userId);
    setState(() {
      _avatarUrl = avatarUrl;
      _isLoading = false;
    });
  }

  Future<void> _loadIdCardImage() async {
    setState(() {
      _isLoading = true;
    });

    final idCardUrl = await _cardService.getIdCardUrl(userId);
    setState(() {
      _idCardUrl = idCardUrl;
      _isLoading = false;
    });
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final response = await _supabaseClient
          .from('users')
          .select('name, phone')
          .eq('id', user.id) // Ensure this matches your column name
          .single();

      _nameController.text = response['name'] ?? '';
      _phoneController.text = response['phone'] ?? '';
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST:301') {
        print('No existing data for user.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching user data: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      final imageFile = File(pickedFile.path);
      final imageUrl = await _cardService.uploadProfileImage(imageFile, userId);

      if (imageUrl != null) {
        await _cardService.updateProfile(userId, imageUrl, _idCardUrl ?? '');
        setState(() {
          _avatarUrl = imageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile image updated!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload image'),
        ));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadIdCard() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
      });

      final imageFile = File(pickedFile.path);
      final idCardUrl = await _cardService.uploadIdCardImage(imageFile, userId);

      if (idCardUrl != null) {
        await _cardService.updateProfile(userId, _avatarUrl ?? '', idCardUrl);
        setState(() {
          _idCardUrl = idCardUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ID card updated!'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to upload ID card'),
        ));
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final phone = _phoneController.text;

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both name and phone number')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _supabaseClient.from('users').update({
        'name': name,
        'phone': phone,
      }).eq('id', user.id); // Using 'id' to update user info

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating profile: $e'),
      ));
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
        title: Text('Dokumen Pendukung',
            style:
                TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(height: 40),
                      Text('NIK / KTP',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: _uploadIdCard,
                        child: _idCardUrl != null
                            ? Image.network(_idCardUrl!, height: 100)
                            : Container(
                                height: 100,
                                color: Colors.blue[300],
                                child: Center(
                                    child: Text('Tap to upload ID card')),
                              ),
                      ),
                      SizedBox(height: 20),
                      Text('Dokumen Pendukung Lain',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          // Implement the upload functionality here
                          // _uploadIdCard(); // Call the upload method when tapped
                        },
                        child: Image.asset(
                          'assets/other_doc.png', // Correct way to use AssetImage
                          height: 100, // Set the height for the asset image
                          fit: BoxFit
                              .cover, // Optional: to maintain aspect ratio
                        ),
                      ),

                      // ElevatedButton(
                      //   onPressed: _submit,
                      //   child: Text('Save Changes'),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
