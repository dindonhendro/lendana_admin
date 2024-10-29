import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UpdateMemberPage extends StatefulWidget {
  final String id; // ID of the member to update
  final VoidCallback onMemberUpdated; // Callback to refresh member list

  UpdateMemberPage({required this.id, required this.onMemberUpdated});

  @override
  _UpdateMemberPageState createState() => _UpdateMemberPageState();
}

class _UpdateMemberPageState extends State<UpdateMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  Map<String, dynamic>? _memberData;
  bool _isLoading = true;

  // Fields to hold image paths
  String? _profileImagePath;
  String? _passportImagePath;
  String? _identityImagePath;
  String? _familyImagePath;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    try {
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();

      if (response != null) {
        setState(() {
          _memberData = response;
          _profileImagePath = _memberData!['profile_image_url'];
          _passportImagePath = _memberData!['passport_image_url'];
          _identityImagePath = _memberData!['identity_image_url'];
          _familyImagePath = _memberData!['family_image_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching member data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage(String? filePath, String field) async {
    if (filePath == null) return;

    final fileName = filePath.split('/').last;
    final file = File(filePath); // Create File object

    try {
      // Upload the file
      final uploadResponse =
          await _supabaseClient.storage.from('members').upload(fileName, file);

      if (uploadResponse.isEmpty) {
        _showSnackBar('Error uploading image: ');
        return;
      }

      // Get the public URL of the uploaded file
      final publicUrl =
          _supabaseClient.storage.from('members').getPublicUrl(fileName);
      await _supabaseClient
          .from('members')
          .update({field: publicUrl}).eq('id', widget.id);

      _showSnackBar('Image uploaded successfully!');
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    }
  }

  Future<void> _updateMember() async {
    final updates = {
      'name': _memberData!['name'],
      'email': _memberData!['email'],
      'phone': _memberData!['phone'],
      'nik': _memberData!['nik'],
      'dob': _memberData!['dob'],
      'address': _memberData!['address'],
      'loan_amount': _memberData!['loan_amount'],
    };

    // Update member information
    final response = await _supabaseClient
        .from('members')
        .update(updates)
        .eq('id', widget.id);

    if (response.error == null) {
      // Call image upload for each image if the path is set
      await _uploadImage(_profileImagePath, 'profile_image_url');
      await _uploadImage(_passportImagePath, 'passport_image_url');
      await _uploadImage(_identityImagePath, 'identity_image_url');
      await _uploadImage(_familyImagePath, 'family_image_url');

      _showSnackBar('Member updated successfully!');
      widget.onMemberUpdated(); // Call the callback to refresh the member list
      Navigator.pop(context);
    } else {
      _showSnackBar('Error updating member: ${response.error?.message}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Member')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _memberData == null
              ? Center(child: Text('No member data found.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildEditableInfoRow('Name', _memberData!['name'],
                          (value) {
                        setState(() {
                          _memberData!['name'] = value;
                        });
                      }),
                      _buildEditableInfoRow('Email', _memberData!['email'],
                          (value) {
                        setState(() {
                          _memberData!['email'] = value;
                        });
                      }),
                      _buildEditableInfoRow('Phone', _memberData!['phone'],
                          (value) {
                        setState(() {
                          _memberData!['phone'] = value;
                        });
                      }),
                      _buildEditableInfoRow('NIK', _memberData!['nik'],
                          (value) {
                        setState(() {
                          _memberData!['nik'] = value;
                        });
                      }),
                      _buildEditableInfoRow(
                          'Date of Birth', _memberData!['dob'], (value) {
                        setState(() {
                          _memberData!['dob'] = value;
                        });
                      }),
                      _buildEditableInfoRow('Address', _memberData!['address'],
                          (value) {
                        setState(() {
                          _memberData!['address'] = value;
                        });
                      }),
                      _buildEditableInfoRow(
                          'Loan Amount', _memberData!['loan_amount'], (value) {
                        setState(() {
                          _memberData!['loan_amount'] = value;
                        });
                      }),
                      SizedBox(height: 20),
                      _buildImageSection('Profile Image', _profileImagePath,
                          (path) => setState(() => _profileImagePath = path)),
                      _buildImageSection('Passport Image', _passportImagePath,
                          (path) => setState(() => _passportImagePath = path)),
                      _buildImageSection('Identity Image', _identityImagePath,
                          (path) => setState(() => _identityImagePath = path)),
                      _buildImageSection('Family Image', _familyImagePath,
                          (path) => setState(() => _familyImagePath = path)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _updateMember,
                        child: Text('Update Member'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEditableInfoRow(
      String label, String value, Function(String) onChanged) {
    TextEditingController controller = TextEditingController(text: value);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 150,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(border: OutlineInputBorder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
      String label, String? imageUrl, Function(String?) onImageChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(imageUrl,
                height: 150, width: 150, fit: BoxFit.cover)
            : _buildImagePlaceholder('No image uploaded'),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: () async {
            final filePath = await FilePicker.platform.pickFiles(
              type: FileType.image,
            );
            if (filePath != null) {
              onImageChanged(filePath.files.single.path);
            }
          },
          child: Text('Upload Image'),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImagePlaceholder(String message) {
    return Container(
      height: 150,
      width: 150,
      color: Colors.grey[200],
      child: Center(child: Text(message)),
    );
  }
}
