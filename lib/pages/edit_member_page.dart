import 'package:flutter/material.dart';
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
  bool _isLoading = false;

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
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill out all fields before submitting.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Perform the update and select the updated data
      final response = await _supabaseClient
          .from('members')
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
