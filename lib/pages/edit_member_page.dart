import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMemberPage extends StatefulWidget {
  final String id; // Member ID
  final Function onMemberUpdated; // Callback to refresh member list

  EditMemberPage({required this.id, required this.onMemberUpdated, Key? key})
      : super(key: key);

  @override
  _EditMemberPageState createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails(); // Fetch member details when page is initialized
  }

  // Fetch member details from Supabase
  Future<void> _fetchMemberDetails() async {
    setState(() => _isLoading = true);

    // Fetch member details
    final response = await Supabase.instance.client
        .from('members')
        .select()
        .eq('id', widget.id)
        .single();

    // Populate the text controllers with the member's data
    if (response != null) {
      _nameController.text = response['name'] ?? '';
      _emailController.text = response['email'] ?? '';
      _phoneController.text = response['phone'] ?? '';
      _nikController.text = response['nik'] ?? '';
      _dobController.text = response['dob'] ?? '';
      _addressController.text = response['address'] ?? '';
      _loanAmountController.text = response['loan_amount']?.toString() ?? '0';
    } else {
      _showSnackBar('Error fetching member details: Member not found.');
    }

    setState(() => _isLoading = false);
  }

  // Show Snackbar method
  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Save updated member information
  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please complete all required fields before saving.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Debug information
      print('Updating member with ID: ${widget.id}');

      // Check if the ID exists
      final checkResponse = await Supabase.instance.client
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();

      // Check if the response is empty
      if (checkResponse == null) {
        _showSnackBar('Member not found with ID: ${widget.id}');
        return; // Exit the method if the member does not exist
      }

      // Execute the update query
      final updateResponse = await Supabase.instance.client
          .from('members')
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'nik': _nikController.text,
            'dob': _dobController.text,
            'address': _addressController.text,
            'loan_amount': int.tryParse(_loanAmountController.text
                    .replaceAll('Rp ', '')
                    .replaceAll('.', '')) ??
                0,
          })
          .eq('id', widget.id) // Where clause
          .select(); // Using select to return the updated data

      // Check the affected rows
      if (updateResponse.isNotEmpty) {
        print('Update successful: $updateResponse');
        widget.onMemberUpdated(); // Notify parent to refresh
        _showSnackBar('Member updated successfully!');
        Navigator.pop(context);
      } else {
        _showSnackBar('Error updating member: No rows affected.');
      }
    } catch (e) {
      print('Error updating member: $e'); // Log the error for debugging
      _showSnackBar('Error updating member: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
            : Column(
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
                    onPressed: _saveChanges,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
      ),
    );
  }
}
