import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/bank_dashboard.dart';
import 'package:lendana_admin/pages/edit_member_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabaseClient = Supabase.instance.client;
  List<dynamic> _members = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabaseClient.from('members').select();

      print("Fetched members: $response"); // Debug print

      if (response != null) {
        setState(() {
          _members = response;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching members: No data returned.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching members: $e'),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addMember() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberPage(onMemberAdded: _fetchMembers),
      ),
    );
  }

  Future<void> _updateMember(dynamic member) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMemberPage(
          id: member['id'],
          onMemberUpdated: _fetchMembers,
        ),
      ),
    );
  }

  Future<void> _deleteMember(dynamic member) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Member'),
        content: Text('Are you sure you want to delete this member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await _supabaseClient
                    .from('members')
                    .delete()
                    .eq('id', member['id']);

                if (response != null) {
                  _fetchMembers();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Member deleted successfully!'),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error deleting member: No data returned.'),
                  ));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error deleting member: $e'),
                ));
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Admin Dashboard'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: _addMember,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BankDashboard()),
            );
          },
          child: Icon(Icons.money),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _members.isEmpty
                ? Center(child: Text('No members found.'))
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];

                      return GestureDetector(
                        onTap: () =>
                            _updateMember(member), // Navigate to EditMemberPage
                        child: Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display member name
                                Text(
                                  member['name'] ?? 'No Name',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),

                                // Display member email
                                Text(
                                  'Email: ${member['email'] ?? 'No Email'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),

                                // Display member phone
                                Text(
                                  'Phone: ${member['phone'] ?? 'No Phone'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),

                                // Display member NIK
                                Text(
                                  'NIK: ${member['nik'] ?? 'No NIK'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),

                                // Display member Date of Birth
                                Text(
                                  'DOB: ${member['dob'] ?? 'No DOB'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 4),

                                // Display member Address
                                Text(
                                  'Address: ${member['address'] ?? 'No Address'}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                SizedBox(height: 16),

                                // Optionally add more details like profile image or other fields here

                                // Edit and Delete buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () =>
                                          _updateMember(member), // Edit action
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _deleteMember(
                                          member), // Delete action
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ));
  }
}
