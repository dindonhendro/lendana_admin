import 'dart:io'; // For handling files
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMemberPage extends StatefulWidget {
  final Function onMemberAdded;
  AddMemberPage({required this.onMemberAdded});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  XFile? _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = selectedImage;
    });
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please complete all fields and upload an image.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Upload the profile image to Supabase storage
      final file = File(_image!.path); // Create a File object from the path

      await _supabaseClient.storage
          .from('profile_images') // Ensure this bucket exists in Supabase
          .upload('public/${_image!.name}', file);

      // Get the public URL of the uploaded image
      final imageUrl = _supabaseClient.storage
          .from('profile_images')
          .getPublicUrl('public/${_image!.name}');

      // Step 2: Insert the member data into the 'members' table
      final memberResponse = await _supabaseClient.from('members').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'profile_image_url': imageUrl, // Store image URL
        'is_approved': false, // Member not approved yet
      }).select(); // Select the inserted row to get the member ID

      if (memberResponse.isEmpty) {
        throw Exception('Error adding member.');
      }

      final memberId =
          memberResponse.first['id']; // Get the inserted member's ID

      // Step 3: Insert into the 'loan_applications' table
      final loanResponse =
          await _supabaseClient.from('loan_applications').insert({
        'member_id': memberId, // Use the member ID from the previous insertion
        'status': 'pending', // Initial loan status
        'reviewed_by': null, // Bank admin will review later
      }).select(); // Use select to retrieve data

      if (loanResponse.isNotEmpty) {
        widget.onMemberAdded(); // Refresh the member list
        Navigator.pop(context); // Go back to AdminDashboard
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding member and loan application: $e'),
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
      appBar: AppBar(title: Text('Add Member')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                    ),
                    TextField(
                      controller: _nikController,
                      decoration: InputDecoration(labelText: 'NIK'),
                    ),
                    TextField(
                      controller: _dobController,
                      decoration: InputDecoration(labelText: 'Date of Birth'),
                    ),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: 'Address'),
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                    ),
                    SizedBox(height: 10),
                    _image == null
                        ? Text('No image selected.')
                        : Image.file(File(_image!.path)), // Display image
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Select Profile Image'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
