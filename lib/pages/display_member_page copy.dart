import 'package:flutter/material.dart';
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

  // Show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
