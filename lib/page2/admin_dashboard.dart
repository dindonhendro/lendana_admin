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
  List<dynamic> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = "";

  final Color primaryColor = Colors.teal;
  final Color secondaryColor = Colors.white;
  final Color accentColor = Colors.amber;

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
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching members: $e'),
        backgroundColor: Colors.red,
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

        return nameMatch || statusMatch;
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
                    backgroundColor: primaryColor,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error deleting member: No data returned.'),
                    backgroundColor: Colors.red,
                  ));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error deleting member: $e'),
                  backgroundColor: Colors.red,
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
        backgroundColor: primaryColor,
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
        backgroundColor: accentColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _filterMembers,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
                filled: true,
                fillColor: secondaryColor,
              ),
            ),
            SizedBox(height: 16),
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
                                margin: EdgeInsets.symmetric(vertical: 8),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                shadowColor: Colors.grey.withOpacity(0.5),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => _updateMember(member),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Profile image with gradient background
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.tealAccent,
                                                Colors.teal
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: ClipOval(
                                            child: member[
                                                        'profile_image_url'] !=
                                                    null
                                                ? Image.network(
                                                    member['profile_image_url'],
                                                    width: 70,
                                                    height: 70,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Icon(
                                                        Icons.person,
                                                        size: 70,
                                                        color: Colors.grey[400],
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    size: 70,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                        ),
                                        SizedBox(width: 16),

                                        // Member details with modern typography
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member['name'] ?? 'No Name',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 6),
                                              Text(
                                                'Email: ${member['email'] ?? 'No Email'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Phone: ${member['phone'] ?? 'No Phone'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'NIK: ${member['nik'] ?? 'No NIK'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'DOB: ${member['dob'] ?? 'No DOB'}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              SizedBox(height: 8),

                                              // Display Loan Application Status with badge-like appearance
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 4, horizontal: 8),
                                                decoration: BoxDecoration(
                                                  color: status == 'approved'
                                                      ? Colors.green[100]
                                                      : status == 'rejected'
                                                          ? Colors.red[100]
                                                          : Colors.orange[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Loan Status: $status',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: status == 'approved'
                                                        ? Colors.green
                                                        : status == 'rejected'
                                                            ? Colors.red
                                                            : Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 16),

                                        // Edit and Delete buttons
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Edit Button
                                            ElevatedButton(
                                              onPressed: () => _updateMember(
                                                  member), // Call update member method
                                              child: Text('Edit'),
                                              style: ElevatedButton.styleFrom(
                                                //  primary: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 8),
                                            // Delete Button
                                            CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.red,
                                              child: IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () => () {}
                                                  //_deleteMember(
                                                  //    member), // Call delete member method
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
