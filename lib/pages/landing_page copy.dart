import 'package:flutter/material.dart';
import 'package:lendana_admin/pages/admin_dashboard.dart';
import 'package:lendana_admin/pages/add_member_page.dart';
import 'package:lendana_admin/pages/loan_status_report_page.dart';

class LandingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome User'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome User',
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
                          builder: (context) => AdminDashboard(),
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
