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
  final _experienceController = TextEditingController();
  final _bankController = TextEditingController();
  final _amountController = TextEditingController();

  // Dropdown value controllers
  String? _genderValue;
  String? _statusValue;
  String? _educationValue;
  String? _occupationValue;
  String? _destCountryValue;
  String? _statusApplicationValue;

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
          .select(
              'name, phone, nik, dob, gender, status, address, education, occupation, dest_country, experience, bank, amount, status_aplication')
          .eq('user_id', user.id)
          .single();

      // Populate the text fields with the fetched data
      _nameController.text = response['name'] ?? '';
      _phoneController.text = response['phone'] ?? '';
      _nikController.text = response['nik'] ?? '';
      _dobController.text = response['dob'] ?? '';
      _addressController.text = response['address'] ?? '';
      _experienceController.text = response['experience'] ?? '';
      _bankController.text = response['bank'] ?? '';
      _amountController.text = response['amount'] ?? '';

      // Set dropdown values
      _genderValue = response['gender'];
      _statusValue = response['status'];
      _educationValue = response['education'];
      _occupationValue = response['occupation'];
      _destCountryValue = response['dest_country'];
      _statusApplicationValue = response['status_aplication'];
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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
    final experience = _experienceController.text;
    final bank = _bankController.text;
    final amount = _amountController.text;

    if (name.isEmpty || phone.isEmpty || nik.isEmpty) {
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
          'education': _educationValue,
          'occupation': _occupationValue,
          'dest_country': _destCountryValue,
          'experience': experience,
          'bank': bank,
          'amount': amount,
          'status_aplication': _statusApplicationValue,
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
          'education': _educationValue,
          'occupation': _occupationValue,
          'dest_country': _destCountryValue,
          'experience': experience,
          'bank': bank,
          'amount': amount,
          'status_aplication': _statusApplicationValue,
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
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nikController,
                      decoration: InputDecoration(labelText: 'NIK'),
                    ),
                    SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dobController,
                          decoration:
                              InputDecoration(labelText: 'Date of Birth'),
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
                      decoration: InputDecoration(labelText: 'Gender'),
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
                      decoration: InputDecoration(labelText: 'Status'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Address'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _educationValue,
                      items: [
                        DropdownMenuItem(
                            value: 'High School', child: Text('High School')),
                        DropdownMenuItem(
                            value: 'Bachelor', child: Text('Bachelor')),
                        DropdownMenuItem(
                            value: 'Master', child: Text('Master')),
                        DropdownMenuItem(value: 'PhD', child: Text('PhD')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _educationValue = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Education'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _occupationValue,
                      items: [
                        DropdownMenuItem(
                            value: 'Student', child: Text('Student')),
                        DropdownMenuItem(
                            value: 'Employee', child: Text('Employee')),
                        DropdownMenuItem(
                            value: 'Freelancer', child: Text('Freelancer')),
                        DropdownMenuItem(
                            value: 'Unemployed', child: Text('Unemployed')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _occupationValue = value!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Occupation'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _destCountryValue,
                      items: [
                        DropdownMenuItem(value: 'USA', child: Text('USA')),
                        DropdownMenuItem(value: 'Japan', child: Text('Japan')),
                        DropdownMenuItem(value: 'Korea', child: Text('Korea')),
                        DropdownMenuItem(
                            value: 'Indonesia', child: Text('Indonesia')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _destCountryValue = value!;
                        });
                      },
                      decoration:
                          InputDecoration(labelText: 'Destination Country'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _experienceController,
                      decoration: InputDecoration(labelText: 'Experience'),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _statusApplicationValue,
                      items: [
                        DropdownMenuItem(
                            value: 'Applied', child: Text('Applied')),
                        DropdownMenuItem(
                            value: 'In Review', child: Text('In Review')),
                        DropdownMenuItem(
                            value: 'Accepted', child: Text('Accepted')),
                        DropdownMenuItem(
                            value: 'Rejected', child: Text('Rejected')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _statusApplicationValue = value!;
                        });
                      },
                      decoration:
                          InputDecoration(labelText: 'Application Status'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _bankController,
                      decoration: InputDecoration(labelText: 'Bank'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Amount'),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Submit Data Calon  Pekerja Migran'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
