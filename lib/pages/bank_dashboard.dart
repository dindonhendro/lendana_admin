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

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 5; // Number of items to show per page
  int _totalItems = 0; // Total items count
  bool _hasNextPage = true; // Check if there's a next page

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
          .order('created_at', ascending: false)
          .range((_currentPage - 1) * _itemsPerPage,
              _currentPage * _itemsPerPage - 1);

      // Debugging log to see the fetched data
      print('Fetched loan applications: $response');

      if (response != null && response.isNotEmpty) {
        setState(() {
          _loans = response;
          _filteredLoans = response; // Initialize filtered list
          _totalItems = response.length; // Update total items count
          _hasNextPage = response.length ==
              _itemsPerPage; // Check if more items are available
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

  // Show confirmation dialog before updating loan status
  Future<void> _confirmUpdateLoanStatus(dynamic loan, String status) async {
    final action = status == 'approved' ? 'approve' : 'reject';

    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm $action Loan'),
          content: Text('Are you sure you want to $action this loan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldProceed == true) {
      await _updateLoanStatus(loan, status);
    }
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
        setState(() {
          loan['status'] = status;
          // Disable buttons after action
          loan['canApprove'] = false;
          loan['canReject'] = false;
        });
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

  // Navigate to the next page
  void _nextPage() {
    if (_hasNextPage) {
      setState(() {
        _currentPage++;
      });
      _fetchLoanApplications();
    }
  }

  // Navigate to the previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchLoanApplications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank Dashboard - Loan Reviews'),
        actions: [
          FutureBuilder<dynamic>(
            future: _fetchProfileImage(),
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
                                        ElevatedButton(
                                          onPressed: loan['status'] == 'pending'
                                              ? () => _confirmUpdateLoanStatus(
                                                  loan, 'approved')
                                              : null,
                                          child: Text('Approve'),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: loan['status'] == 'pending'
                                              ? () => _confirmUpdateLoanStatus(
                                                  loan, 'rejected')
                                              : null,
                                          child: Text('Reject'),
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
          // Pagination controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _previousPage,
                child: Text('Previous'),
              ),
              Text('Page $_currentPage'),
              TextButton(
                onPressed: _nextPage,
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchLoanApplications,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Loan Applications',
      ),
    );
  }

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
              'Member: ${member['name'] ?? 'N/A'}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Loan Amount: ${loan['loan_amount'] ?? 'N/A'}'),
            Text('Loan Status: ${loan['status'] ?? 'N/A'}'),
            Text(
                'Created At: ${loan['created_at']?.toString().substring(0, 10) ?? 'N/A'}'),
            // Add more details if necessary
          ],
        ),
      ),
    );
  }
}
