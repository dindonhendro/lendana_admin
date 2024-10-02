import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/bank_dashboard.dart';
import 'package:lendana_admin/pages/edit_member_page.dart';
import 'package:lendana_admin/pages/loan_status_report_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabaseClient = Supabase.instance.client;
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = "";

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
      final response = await _supabaseClient.from('members').select(
          '*, loan_applications(status)'); // Fetching status from loan_applications

      print("Fetched members: $response"); // Debug print

      if (response != null) {
        setState(() {
          _members = response;
          _filteredMembers = response; // Initialize filtered list
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

  void _filterMembers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredMembers = _members.where((member) {
        final nameMatch =
            member['name']?.toLowerCase().contains(query.toLowerCase()) ??
                false;
        final statusMatch = member['loan_applications'] != null &&
                member['loan_applications'][0]['status']
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
            false;
        // Add other conditions based on member fields if needed

        return nameMatch ||
            statusMatch; // Adjust this based on desired search logic
      }).toList();
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
            MaterialPageRoute(builder: (context) => LoanStatusReportPage()),
          );
        },
        child: Icon(Icons.money),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterMembers,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? Center(child: Text('No members found.'))
                    : ListView.builder(
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = _filteredMembers[index];
                          final status = member['loan_applications'] != null
                              ? member['loan_applications'][0]['status']
                              : 'No Status'; // Fetching status from loan_applications

                          return GestureDetector(
                            onTap: () => _updateMember(member),
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Stack(
                                  children: [
                                    // Member details
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name'] ?? 'No Name',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Email: ${member['email'] ?? 'No Email'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Phone: ${member['phone'] ?? 'No Phone'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'NIK: ${member['nik'] ?? 'No NIK'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'DOB: ${member['dob'] ?? 'No DOB'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Address: ${member['address'] ?? 'No Address'}',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        SizedBox(height: 16),

                                        // Display Loan Application Status
                                        Text(
                                          'Loan Status: $status',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: status == 'approved'
                                                ? Colors.green
                                                : status == 'rejected'
                                                    ? Colors.red
                                                    : Colors.orange,
                                          ),
                                        ),
                                        SizedBox(height: 16),

                                        // Edit and Delete buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _updateMember(member),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () =>
                                                  _deleteMember(member),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Profile image in the top right corner
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: member['profile_image_url'] != null
                                          ? ClipOval(
                                              child: Image.network(
                                                member['profile_image_url'],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 60,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 60,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
