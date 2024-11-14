import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisplayMemberPage extends StatefulWidget {
  final String memberId; // ID of the member to display

  DisplayMemberPage({required this.memberId});

  @override
  _DisplayMemberPageState createState() => _DisplayMemberPageState();
}

class _DisplayMemberPageState extends State<DisplayMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  Map<String, dynamic>? _memberData;
  bool _isLoading = true;
  String? _filePath; // To store the file path after saving

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
          .eq('id', widget.memberId)
          .single();

      if (response != null) {
        setState(() {
          _memberData = response;
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

  Future<void> _saveToFile() async {
    if (_memberData == null) return;

    try {
      // Convert the member data to a text format for saving
      final profileText = '''
Name          : ${_memberData!['name'] ?? 'N/A'}
Email         : ${_memberData!['email'] ?? 'N/A'}
Phone         : ${_memberData!['phone'] ?? 'N/A'}
NIK           : ${_memberData!['nik'] ?? 'N/A'}
Date of Birth : ${_memberData!['dob'] ?? 'N/A'}
Address       : ${_memberData!['address'] ?? 'N/A'}
Religion        : ${_memberData!['religion'] ?? 'N/A'}
Education Level  : ${_memberData!['education'] ?? 'N/A'}
Gender  : ${_memberData!['gender'] ?? 'N/A'}
Marrital Status  : ${_memberData!['status'] ?? 'N/A'}
Loan Amount   : ${_memberData!['loan_amount'] ?? 'N/A'}
Profile Image URL    : ${_memberData!['profile_image_url'] ?? 'N/A'}
Passport Image URL   : ${_memberData!['passport_image_url'] ?? 'N/A'}
Identity Image URL   : ${_memberData!['identity_image_url'] ?? 'N/A'}
Family Image URL     : ${_memberData!['family_image_url'] ?? 'N/A'}
      ''';

      // Get the directory to save the file
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'member_${widget.memberId}_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      // Write the profile data to the file
      await file.writeAsString(profileText);

      setState(() {
        _filePath = file.path;
      });

      _showSnackBar('Profile saved to file: $fileName');
    } catch (e) {
      _showSnackBar('Error saving to file: $e');
    }
  }

  // Show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Member Details')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _memberData == null
              ? Center(child: Text('No member data found.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      _buildInfoRow('Name', _memberData!['name']),
                      _buildInfoRow('Email', _memberData!['email']),
                      _buildInfoRow('Phone', _memberData!['phone']),
                      _buildInfoRow('NIK', _memberData!['nik']),
                      _buildInfoRow(
                          'Date of Birth', _memberData!['dob'] ?? 'N/A'),
                      _buildInfoRow('Address', _memberData!['address']),
                      _buildInfoRow('Religion', _memberData!['religion']),
                      _buildInfoRow(
                          'Education Level', _memberData!['education']),
                      _buildInfoRow('Gender', _memberData!['gender']),
                      _buildInfoRow('Marrital Status', _memberData!['status']),
                      _buildInfoRow('Loan Amount', _memberData!['loan_amount']),
                      SizedBox(height: 20),
                      _buildImageSection(
                          'Profile Image', _memberData!['profile_image_url']),
                      _buildImageSection(
                          'Passport Image', _memberData!['passport_image_url']),
                      _buildImageSection(
                          'Identity Image', _memberData!['identity_image_url']),
                      _buildImageSection(
                          'Family Image', _memberData!['family_image_url']),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveToFile,
                        child: Text('Save to File'),
                      ),
                      if (_filePath != null) ...[
                        SizedBox(height: 20),
                        Text(
                          'File saved at: $_filePath',
                          style: TextStyle(color: Colors.green),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Open the file for printing or viewing in an external application
                            if (_filePath != null) {
                              File(_filePath!).open();
                            }
                          },
                          child: Text('Open and Print File'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  // Build information row for text fields
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  // Build image preview section
  Widget _buildImageSection(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        imageUrl.isNotEmpty
            ? Image.network(imageUrl,
                height: 150, width: 150, fit: BoxFit.cover)
            : _buildImagePlaceholder('No image uploaded'),
        SizedBox(height: 16),
      ],
    );
  }

  // Placeholder for missing images
  Widget _buildImagePlaceholder(String message) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(message)),
    );
  }
}
