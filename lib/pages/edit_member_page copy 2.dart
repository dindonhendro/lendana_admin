import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add image picker package
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMemberPage extends StatefulWidget {
  final String id; // Accept the member ID
  final Function onMemberUpdated;

  const EditMemberPage(
      {Key? key, required this.id, required this.onMemberUpdated})
      : super(key: key);

  @override
  _EditMemberPageState createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController(); // DOB controller
  final _addressController = TextEditingController(); // Address controller

  bool _isLoading = false;
  String? _profileImageUrl; // To hold the profile image URL
  File? _newProfileImage; // To hold the selected image file for update

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single(); // Get the single record

      if (response != null) {
        _nameController.text = response['name'];
        _emailController.text = response['email'];
        _dobController.text = response['dob']; // Fetch DOB
        _addressController.text = response['address']; // Fetch Address
        _profileImageUrl = response['profile_image_url']; // Get the image URL
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching member details: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMember() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill out all fields before submitting.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;

      // If a new profile image was selected, upload it first
      if (_newProfileImage != null) {
        imageUrl = await _uploadImage(_newProfileImage!);
      }

      // Perform the update
      final response = await _supabaseClient
          .from('members')
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
            'dob': _dobController.text, // Update DOB
            'address': _addressController.text, // Update Address
            if (imageUrl != null)
              'profile_image_url': imageUrl, // Update image URL if changed
          })
          .eq('id', widget.id)
          .select(); // This will retrieve the updated row data

      if (response != null && response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Member updated successfully!'),
        ));
        widget.onMemberUpdated(); // Refresh the member list
        Navigator.pop(context); // Go back after updating
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating member: No data returned.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating member: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      // Upload the image and get the file path as a response
      final filePath = 'public/${widget.id}/profile_image.png';
      final response = await _supabaseClient.storage
          .from('profile_images') // Assuming 'avatars' is the bucket name
          .upload(filePath, image);

      // If upload is successful, generate the public URL for the image
      if (response != null) {
        final publicUrl = _supabaseClient.storage
            .from('profile_images')
            .getPublicUrl(filePath);
        return publicUrl;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error uploading image: $e'),
      ));
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path); // Update the selected image
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose(); // Dispose DOB controller
    _addressController.dispose(); // Dispose Address controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _newProfileImage != null
                                ? FileImage(_newProfileImage!)
                                : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                    : AssetImage('assets/default_avatar.png')
                                        as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateMember,
                        child: Text('Update Member'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
