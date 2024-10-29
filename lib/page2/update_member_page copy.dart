import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateMemberPage extends StatefulWidget {
  final String id; // Member ID passed from previous page
  final Function onMemberUpdated; // Callback to refresh the member list

  const UpdateMemberPage({
    Key? key,
    required this.id,
    required this.onMemberUpdated,
  }) : super(key: key);

  @override
  _UpdateMemberPageState createState() => _UpdateMemberPageState();
}

class _UpdateMemberPageState extends State<UpdateMemberPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  List<String> imageUrls = List.filled(10, ''); // For storing image URLs

  @override
  void initState() {
    super.initState();
    print('Received ID: ${widget.id}'); // Debugging: Check received ID
    _fetchMemberData(); // Fetch member data to prefill the form
  }

  Future<void> _fetchMemberData() async {
    try {
      // Fetch member data by ID
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id) // Ensure 'id' column is correct in your table
          .single(); // Fetch single member

      if (response == null) {
        print('No member found with the provided ID');
        return;
      }

      // Debugging: Member found
      print('Member found: ${response['name']}');

      // Prefill form fields
      setState(() {
        _nameController.text = response['name'] ?? '';
        _emailController.text = response['email'] ?? '';
        _phoneController.text = response['phone'] ?? '';
        _nikController.text = response['nik'] ?? '';
        _dobController.text = response['dob'] ?? '';
        _addressController.text = response['address'] ?? '';
        _loanAmountController.text = response['loan_amount']?.toString() ?? '';
        imageUrls[0] = response['profile_image_url'] ?? '';
        imageUrls[1] = response['passport_image_url'] ?? '';
        imageUrls[2] = response['identity_image_url'] ?? '';
        imageUrls[3] = response['family_image_url'] ?? '';
        imageUrls[4] = response['doc1_image_url'] ?? '';
        imageUrls[5] = response['doc2_image_url'] ?? '';
        imageUrls[6] = response['doc3_image_url'] ?? '';
        imageUrls[7] = response['doc4_image_url'] ?? '';
        imageUrls[8] = response['doc5_image_url'] ?? '';
        imageUrls[9] = response['doc6_image_url'] ?? '';
      });
    } catch (error) {
      print('Error fetching member data: $error');
    }
  }

  Future<void> _updateMember() async {
    try {
      // Update member data
      final updateResponse = await _supabaseClient
          .from('members')
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'nik': _nikController.text,
            'dob': _dobController.text,
            'address': _addressController.text,
            'loan_amount': _loanAmountController.text
                .replaceAll('Rp ', '')
                .replaceAll('.', ''),
            'profile_image_url': imageUrls[0],
            'passport_image_url': imageUrls[1],
            'identity_image_url': imageUrls[2],
            'family_image_url': imageUrls[3],
            'doc1_image_url': imageUrls[4],
            'doc2_image_url': imageUrls[5],
            'doc3_image_url': imageUrls[6],
            'doc4_image_url': imageUrls[7],
            'doc5_image_url': imageUrls[8],
            'doc6_image_url': imageUrls[9],
          })
          .eq('id', widget.id)
          .select();

      // Debugging: Check the update response
      if (updateResponse == null || updateResponse.isEmpty) {
        print('No rows updated. Possibly wrong ID.');
        return;
      }

      // Success: Member updated
      print('Member updated successfully');
      widget.onMemberUpdated(); // Call callback to refresh members list
      Navigator.pop(context); // Close the page after updating
    } catch (error) {
      print('Error updating member: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
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
              controller: _loanAmountController,
              decoration: InputDecoration(labelText: 'Loan Amount'),
            ),
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
}
