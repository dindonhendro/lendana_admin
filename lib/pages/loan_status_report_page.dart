import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoanStatusReportPage extends StatefulWidget {
  @override
  _LoanStatusReportPageState createState() => _LoanStatusReportPageState();
}

class _LoanStatusReportPageState extends State<LoanStatusReportPage> {
  final _supabaseClient = Supabase.instance.client;
  List<Map<String, dynamic>> _loanData = []; // List to store grouped data
  bool _isLoading = true;

  // Fetch loan data categorized by status
  Future<void> _fetchLoanStatusData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all loan applications with their statuses
      final response =
          await _supabaseClient.from('loan_applications').select('status');

      if (response != null && response.isNotEmpty) {
        // Manually group the loan applications by status
        final Map<String, int> groupedData = {};

        for (var loan in response) {
          String status = loan['status'] ?? 'Unknown';
          if (groupedData.containsKey(status)) {
            groupedData[status] = groupedData[status]! + 1;
          } else {
            groupedData[status] = 1;
          }
        }

        // Convert the map to a list of maps for easier rendering
        setState(() {
          _loanData = groupedData.entries
              .map((entry) => {'status': entry.key, 'count': entry.value})
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching loan status data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLoanStatusData(); // Fetch data when the page loads
  }

  @override
  Widget build(BuildContext context) {
    // Ensure totalLoans is calculated as an int
    int totalLoans =
        _loanData.fold<int>(0, (sum, loan) => sum + (loan['count'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text('Loan Status Report'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _loanData.isEmpty
                  ? Center(child: Text('No loan data available.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Loans Display
                        Container(
                          padding: EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Loans:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                totalLoans.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Loan Status Summary',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 20),
                        DataTable(
                          columns: [
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Number of Loans')),
                          ],
                          rows: _loanData.map((loan) {
                            return DataRow(
                              cells: [
                                DataCell(Text(loan['status'])),
                                DataCell(Text(loan['count'].toString())),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
            ),
    );
  }
}
