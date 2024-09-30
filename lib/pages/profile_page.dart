import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabaseClient = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();
  String? _avatarUrl; // To store and display the avatar URL
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  // Dropdown value controllers
  String? _genderValue;
  String? _statusValue;

  bool _isLoading = false;

  // Get the current user's ID
  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    // Fetch the current user's profile image URL
    final avatarUrl = await _profileService.getProfileImageUrl(userId);

    setState(() {
      _avatarUrl = avatarUrl;
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
      // Fetch user data from the 'users' table
      final response = await _supabaseClient
          .from('users')
          .select('name, phone, nik, dob, gender, status, address')
          .eq('user_id', user.id)
          .single();

      // Populate the text fields with the fetched data
      _nameController.text = response['name'] ?? '';
      _phoneController.text = response['phone'] ?? '';
      _nikController.text = response['nik'] ?? '';
      _dobController.text = response['dob'] ?? '';
      _addressController.text = response['address'] ?? '';

      // Set dropdown values
      _genderValue = response['gender'];
      _statusValue = response['status'];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month}-${picked.day}";
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

      // Upload image to Supabase
      final imageFile = File(pickedFile.path);
      final imageUrl =
          await _profileService.uploadProfileImage(imageFile, userId);

      if (imageUrl != null) {
        // Update user's profile with the new image URL
        await _profileService.updateProfile(userId, imageUrl);

        // Update UI with the new image URL
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

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    final name = _nameController.text;
    final phone = _phoneController.text;
    final nik = _nikController.text;
    final dob = _dobController.text;
    final address = _addressController.text;

    if (name.isEmpty || phone.isEmpty || nik.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter Name, Phone number and NIK')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final existingResponse = await _supabaseClient
          .from('users')
          .select()
          .eq('user_id', user.id)
          .single();

      if (existingResponse != null) {
        await _supabaseClient.from('users').update({
          'name': name,
          'phone': phone,
          'nik': nik,
          'dob': dob,
          'gender': _genderValue,
          'status': _statusValue,
          'address': address,
        }).eq('user_id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data updated successfully')),
        );
      } else {
        await _supabaseClient.from('users').insert({
          'name': name,
          'phone': phone,
          'nik': nik,
          'dob': dob,
          'gender': _genderValue,
          'status': _statusValue,
          'address': address,
          'user_id': user.id,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data submitted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error occurred: $e')),
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
        title: Text('Profile & Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _uploadImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _avatarUrl != null
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: _avatarUrl == null
                            ? Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    Text(
                        'Kami tidak akan mengedarkan/menjual data pribadi Anda',
                        style: TextStyle(fontSize: 10)),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nikController,
                      decoration: InputDecoration(
                        labelText: 'NIK',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    Text('Kami tidak akan mengedarkan/menjual no NIK Anda',
                        style: TextStyle(fontSize: 10)),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dobController,
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide(
                                color: Colors.blueGrey, // Border color
                                width: 1.0, // Border width
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _genderValue,
                      items: [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _genderValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusValue,
                      items: [
                        DropdownMenuItem(
                            value: 'Single', child: Text('Single')),
                        DropdownMenuItem(
                            value: 'Married', child: Text('Married')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusValue = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                          borderSide: BorderSide(
                            color: Colors.blueGrey, // Border color
                            width: 1.0, // Border width
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit Data'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
