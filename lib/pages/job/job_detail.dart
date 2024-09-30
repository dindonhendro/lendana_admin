import 'package:flutter/material.dart';
import 'package:lendana/pages/loan_page.dart';
// Import LoanPage

class JobDetail extends StatelessWidget {
  final Map<String, dynamic> job;

  JobDetail({required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job['role']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job['role'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Company: ${job['company']}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Country: ${job['country']}", style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text("Salary: ${job['salary']}", style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text("Details: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("${job['detail']}"),
            SizedBox(height: 40),
            // Add a button to navigate to LoanPage
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to LoanPage when button is pressed
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoanPage()),
                  );
                },
                child: Text('Apply for a Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
