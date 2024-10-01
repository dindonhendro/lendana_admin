import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BankDashboard extends StatefulWidget {
  @override
  _BankDashboardState createState() => _BankDashboardState();
}

class _BankDashboardState extends State<BankDashboard> {
  final _supabaseClient = Supabase.instance.client;
  List<dynamic> _loans = [];
  bool _isLoading = false;

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
          .select('*, members(*)') // Fetch related member data
          .order('created_at', ascending: false);

      if (response != null && response.isNotEmpty) {
        setState(() {
          _loans = response;
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
      print(e);
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Approve or Reject Loan
  Future<void> _updateLoanStatus(dynamic loan, String status) async {
    try {
      final response = await _supabaseClient
          .from('loan_applications')
          .update({'status': status}).eq('id', loan['id']);

      if (response != null) {
        _fetchLoanApplications(); // Refresh loan list
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? Center(child: Text('No loan applications found.'))
              : ListView.builder(
                  itemCount: _loans.length,
                  itemBuilder: (context, index) {
                    final loan = _loans[index];
                    final member =
                        loan['members']; // Access member data directly as a Map

                    return ListTile(
                      title: Text(
                          'Member: ${member['name'] ?? 'N/A'}'), // Safely access 'name'
                      subtitle: Text(
                          'Loan Amount: ${loan['loan_amount'] ?? 'N/A'}'), // Safely access loan amount
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () =>
                                _updateLoanStatus(loan, 'approved'),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () =>
                                _updateLoanStatus(loan, 'rejected'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
