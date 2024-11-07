import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/bank_dashboard.dart';
import 'package:lendana_admin/pages/display_member_page.dart';
import 'package:lendana_admin/pages/edit_member_page.dart';
import 'package:lendana_admin/pages/login_page.dart';
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
  int _selectedIndex = 0;
  bool isExpanded = false;

  int totalRecords = 0;
  int pendingCount = 0;
  int approvedCount = 0;
  int rejectedCount = 0;

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
          totalRecords = response.length;
          pendingCount = response
              .where((member) =>
                  member['loan_applications'] != null &&
                  member['loan_applications'][0]['status'] == 'Pending')
              .length;
          approvedCount = response
              .where((member) =>
                  member['loan_applications'] != null &&
                  member['loan_applications'][0]['status'] == 'Approved')
              .length;
          rejectedCount = response
              .where((member) =>
                  member['loan_applications'] != null &&
                  member['loan_applications'][0]['status'] == 'Rejected')
              .length;
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

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 3) {
      // Assuming "Logout" is at index 2
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginPage()), // Navigate to LoginPage
      );
    }
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
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => AddMemberPage()),
              // );
            },
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
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.deepPurple.shade400,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: isExpanded,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusCard(
                          "Total Records", totalRecords, Colors.blue),
                      _buildStatusCard("Pending", pendingCount, Colors.orange),
                      _buildStatusCard("Approved", approvedCount, Colors.green),
                      _buildStatusCard("Rejected", rejectedCount, Colors.red),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    onChanged: (query) => setState(() {
                      _searchQuery = query;
                      _filteredMembers = _members.where((member) {
                        final nameMatch = member['name']
                                ?.toLowerCase()
                                .contains(query.toLowerCase()) ??
                            false;
                        final statusMatch =
                            member['loan_applications'] != null &&
                                    member['loan_applications'].isNotEmpty &&
                                    member['loan_applications'][0]['status']
                                        ?.toLowerCase()
                                        .contains(query.toLowerCase()) ??
                                false;
                        return nameMatch || statusMatch;
                      }).toList();
                    }),
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
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.resolveWith(
                                              (states) => Colors.blue.shade300),
                                      dataRowColor:
                                          MaterialStateProperty.resolveWith(
                                        (states) => states
                                                .contains(MaterialState.hovered)
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
                                        final status =
                                            member['loan_applications'] !=
                                                        null &&
                                                    member['loan_applications']
                                                        .isNotEmpty
                                                ? member['loan_applications'][0]
                                                    ['status']
                                                : 'No Status';
                                        final loanAmount =
                                            member['loan_applications'] !=
                                                        null &&
                                                    member['loan_applications']
                                                        .isNotEmpty
                                                ? member['loan_applications'][0]
                                                            ['loan_amount']
                                                        ?.toString() ??
                                                    '0'
                                                : 'No Amount';

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(
                                                member['name'] ?? 'No Name')),
                                            DataCell(Text(
                                                member['email'] ?? 'No Email')),
                                            DataCell(Text(
                                                member['phone'] ?? 'No Phone')),
                                            DataCell(Text(
                                                member['nik'] ?? 'No NIK')),
                                            DataCell(Text(
                                                member['dob'] ?? 'No DOB')),
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
                                                    onPressed: () {},
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
                                                            memberId:
                                                                member['id'],
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
}
