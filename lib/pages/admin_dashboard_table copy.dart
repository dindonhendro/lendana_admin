import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/bank_dashboard.dart';
import 'package:lendana_admin/pages/display_member_page.dart';
import 'package:lendana_admin/pages/edit_member_page.dart';
import 'package:lendana_admin/pages/update_member_page.dart';
import 'package:lendana_admin/page2/update_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardTable extends StatefulWidget {
  @override
  _AdminDashboardTableState createState() => _AdminDashboardTableState();
}

class _AdminDashboardTableState extends State<AdminDashboardTable> {
  final _supabaseClient = Supabase.instance.client;
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = false;
  String _searchQuery = "";

  final Color primaryColor = Colors.teal;
  final Color secondaryColor = Colors.white;
  final Color accentColor = Colors.amber;
  final Color hoverColor = Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      final response = await _supabaseClient
          .from('members')
          .select('*, loan_applications(status, loan_amount)')
          .eq('admin_id', userId!);

      if (response.isNotEmpty) {
        setState(() {
          _members = response;
          _filteredMembers = response;
        });
      } else {
        _showSnackBar('Error fetching members: No data returned.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error fetching members: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterMembers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredMembers = _members.where((member) {
        final nameMatch =
            member['name']?.toLowerCase().contains(query.toLowerCase()) ??
                false;
        final statusMatch = member['loan_applications'] != null &&
                member['loan_applications'].isNotEmpty &&
                member['loan_applications'][0]['status']
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
            false;
        return nameMatch || statusMatch;
      }).toList();
    });
  }

  Future<void> _addMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMemberPage(onMemberAdded: _fetchMembers),
      ),
    );
  }

  Future<void> _updateMember(dynamic member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateMemberPage(
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

                if (response != null && response.length > 0) {
                  await _fetchMembers();
                  _showSnackBar('Member deleted successfully!', primaryColor);
                } else {
                  _showSnackBar(
                      'Error deleting member: No data returned.', Colors.red);
                }
              } catch (e) {
                _showSnackBar('Error deleting member: $e', Colors.red);
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
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
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor:
                                    MaterialStateProperty.resolveWith(
                                        (states) => Colors.blue.shade300),
                                dataRowColor: MaterialStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(MaterialState.hovered)
                                          ? hoverColor
                                          : secondaryColor,
                                ),
                                headingTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                  fontSize: 16,
                                ),
                                columnSpacing: 16.0,
                                columns: const [
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Email')),
                                  DataColumn(label: Text('Phone')),
                                  DataColumn(label: Text('NIK')),
                                  DataColumn(label: Text('DOB')),
                                  DataColumn(label: Text('Loan Status')),
                                  DataColumn(label: Text('Loan Amount')),
                                  DataColumn(label: Text('Actions')),
                                ],
                                rows: _filteredMembers.map((member) {
                                  final status = member['loan_applications'] !=
                                              null &&
                                          member['loan_applications'].isNotEmpty
                                      ? member['loan_applications'][0]['status']
                                      : 'No Status';

                                  final loanAmount =
                                      member['loan_applications'] != null &&
                                              member['loan_applications']
                                                  .isNotEmpty
                                          ? member['loan_applications'][0]
                                                      ['loan_amount']
                                                  ?.toString() ??
                                              '0'
                                          : 'No Amount';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                          Text(member['name'] ?? 'No Name')),
                                      DataCell(
                                          Text(member['email'] ?? 'No Email')),
                                      DataCell(
                                          Text(member['phone'] ?? 'No Phone')),
                                      DataCell(Text(member['nik'] ?? 'No NIK')),
                                      DataCell(Text(member['dob'] ?? 'No DOB')),
                                      DataCell(Text(status)),
                                      DataCell(Text(loanAmount)),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () =>
                                                  _updateMember(member),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _deleteMember(member),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.visibility,
                                                  color: Colors.green),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        DisplayMemberPage(
                                                      memberId: member['id'],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
