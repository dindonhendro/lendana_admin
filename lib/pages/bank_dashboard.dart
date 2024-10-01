import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankDashboard extends StatefulWidget {
  @override
  _BankDashboardState createState() => _BankDashboardState();
}

class _BankDashboardState extends State<BankDashboard> {
  final _supabaseClient = Supabase.instance.client;
  List<dynamic> _loans = [];
  List<dynamic> _filteredLoans = [];
  bool _isLoading = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchLoanApplications();
  }

  Future<void> _fetchLoanApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabaseClient
          .from('loan_applications')
          .select(
              '*, members(profile_image_url, name)') // Fetch related member data
          .order('created_at', ascending: false);

      // Debugging log to see the fetched data
      print('Fetched loan applications: $response');

      if (response != null && response.isNotEmpty) {
        setState(() {
          _loans = response;
          _filteredLoans = response; // Initialize filtered list
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No loan applications found.'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching loan applications: $e'),
      ));
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _filterLoans(String query) {
    final filtered = _loans.where((loan) {
      final memberName = loan['members']['name']?.toLowerCase() ?? '';
      final loanStatus = loan['status']?.toLowerCase() ?? '';
      return memberName.contains(query.toLowerCase()) ||
          loanStatus.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredLoans = filtered;
      _searchQuery = query;
    });
  }

  // Approve or Reject Loan
  Future<void> _updateLoanStatus(dynamic loan, String status) async {
    try {
      final response = await _supabaseClient
          .from('loan_applications')
          .update({'status': status}).eq('id', loan['id']);

      // Debugging log to see the response
      print('Update response: $response');

      if (response != null) {
        await _fetchLoanApplications(); // Wait for the refresh to complete
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Loan application $status!'),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error updating loan status: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Dashboard - Loan Reviews'),
        actions: [
          // Display profile image from members table
          FutureBuilder<dynamic>(
            future:
                _fetchProfileImage(), // Call a function to fetch the image URL
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show loading indicator
              } else if (snapshot.hasError) {
                return Container(); // Handle error
              } else if (snapshot.hasData) {
                String imageUrl = snapshot.data['profile_image_url'];
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                );
              }
              return Container(); // Default case
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Loans',
                border: OutlineInputBorder(),
              ),
              onChanged: _filterLoans,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredLoans.isEmpty
                    ? Center(child: Text('No loan applications found.'))
                    : ListView.builder(
                        itemCount: _filteredLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _filteredLoans[index];
                          final member = loan['members'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LoanDetailPage(loan: loan),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Member: ${member['name'] ?? 'N/A'}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                        'Loan Amount: ${loan['loan_amount'] ?? 'N/A'}'),
                                    Text(
                                        'Loan Status: ${loan['status'] ?? 'N/A'}'),
                                    Text(
                                        'Created At: ${loan['created_at']?.toString().substring(0, 10) ?? 'N/A'}'),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check),
                                          onPressed: () => _updateLoanStatus(
                                              loan, 'approved'),
                                          tooltip: 'Approve',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close),
                                          onPressed: () => _updateLoanStatus(
                                              loan, 'rejected'),
                                          tooltip: 'Reject',
                                        ),
                                      ],
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

  // Function to fetch the profile image of the logged-in user
  Future<dynamic> _fetchProfileImage() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId != null) {
      final response = await _supabaseClient
          .from('members')
          .select('profile_image_url')
          .eq('id', userId)
          .single();

      return response;
    }

    return null;
  }
}

// New LoanDetailPage to show detailed information
class LoanDetailPage extends StatelessWidget {
  final dynamic loan;

  const LoanDetailPage({Key? key, required this.loan}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final member = loan['members'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Name: ${member['name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Loan Amount: ${loan['loan_amount'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            Text('Loan Status: ${loan['status'] ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            Text(
                'Created At: ${loan['created_at']?.toString().substring(0, 10) ?? 'N/A'}',
                style: TextStyle(fontSize: 18)),
            // Add any additional fields you want to show here
            SizedBox(height: 20),
            Text('Additional Information:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // Display other details related to the loan here
            // e.g. Text('Field Name: ${loan['field_name'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }
}
