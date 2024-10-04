import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/admin_dashboard_table.dart';
import 'package:lendana_admin/pages/mob_admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lendana_admin/pages/admin_dashboard.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/loan_status_report_page.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String? userName;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      try {
        // Fetch user name from the users table based on user_id
        final response = await Supabase.instance.client
            .from('users')
            .select('name') // Adjust based on your schema
            .eq('user_id', user.id) // Assuming user_id is the identifier
            .single(); // Fetch a single record

        if (response != null) {
          setState(() {
            userName = response['name']; // Extracting name from response
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error fetching user name: No data returned.'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        // Handle any errors during the fetch
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching user name: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome ${userName ?? 'User'}'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome ${userName ?? 'User'}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3, // Adjusted for wider layout
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5, // Adjust aspect ratio for better fit
                children: [
                  _buildGridButton(
                    context,
                    title: 'Dashboard',
                    color: Colors.teal[300]!,
                    icon: Icons.dashboard,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminDashboardTable(),
                        ),
                      );
                    },
                  ),
                  _buildGridButton(
                    context,
                    title: 'Add Member',
                    color: Colors.orange[300]!,
                    icon: Icons.person_add,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMemberPage(
                            onMemberAdded: () {
                              // Handle member added callback here
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  _buildGridButton(
                    context,
                    title: 'Reporting',
                    color: Colors.blue[300]!,
                    icon: Icons.bar_chart,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoanStatusReportPage(),
                        ),
                      );
                    },
                  ),
                  _buildGridButton(
                    context,
                    title: 'Data From Mobile Apps',
                    color: Colors.purple[300]!,
                    icon: Icons.dashboard_customize,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MobAdminDashboard(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridButton(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
