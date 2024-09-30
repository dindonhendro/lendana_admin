import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LoanPage extends StatefulWidget {
  @override
  _LoanPageState createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final _supabaseClient = Supabase.instance.client;
  final _bankController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;
  String _bank = '';
  String _amount = '';

  // Formatter for Indonesian Rupiah
  final _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  // Get the current user's ID
  String get userId => _supabaseClient.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _fetchLoanDetails();
  }

  Future<void> _fetchLoanDetails() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      final response = await _supabaseClient
          .from('users')
          .select('bank, amount')
          .eq('user_id', user.id)
          .single();

      if (response != null) {
        setState(() {
          _bank = response['bank'] ?? '';
          // Check if amount is null before parsing
          _amount =
              response['amount'] != null ? response['amount'].toString() : '0';
          _bankController.text = _bank;
          _amountController.text =
              _currencyFormatter.format(int.tryParse(_amount) ?? 0);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching loan details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    final bank = _bankController.text;
    // Handle empty amount correctly
    final amountString =
        _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = amountString.isNotEmpty ? int.tryParse(amountString) : null;

    if (bank.isEmpty || amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both bank and loan amount',
              style: TextStyle(color: Colors.grey[800])),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final user = _supabaseClient.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not logged in. Redirecting to login.')),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }

    try {
      // Check if the user already exists
      final existingResponse = await _supabaseClient
          .from('users')
          .select('user_id')
          .eq('user_id', user.id)
          .single();

      if (existingResponse != null) {
        // If user exists, update bank and amount
        await _supabaseClient.from('users').update({
          'bank': bank,
          'amount': amount,
        }).eq('user_id', user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan details updated successfully')),
        );
      } else {
        // Insert new record if user doesn't exist
        await _supabaseClient.from('users').insert({
          'bank': bank,
          'amount': amount,
          'user_id': user.id,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loan details submitted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank and Loan Amount'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBankCard(
                      bankName: 'Bank BNI',
                      bankLogoAssetPath: 'assets/bankbni.jpg',
                      bankDescription: 'Bank Penyedia KUR untuk PMI dan UKM.',
                      loanRate: '6% per annum',
                    ),
                    _buildBankCard(
                      bankName: 'Bank Nano',
                      bankLogoAssetPath: 'assets/banknano.png',
                      bankDescription:
                          'Innovative bank yang memberikan pinjaman berbasis Syariah.',
                      loanRate: '12.0% per annum',
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _bankController,
                      decoration: InputDecoration(labelText: 'Bank'),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Loan Amount',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        _formatCurrency();
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text('Ajukan Pinjaman'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBankCard({
    required String bankName,
    required String bankLogoAssetPath,
    required String bankDescription,
    required String loanRate,
  }) {
    return GestureDetector(
      onTap: () {
        _selectBank(bankName);
      },
      child: Container(
        color: Colors.grey[100], // Set the background color to a light grey
        child: Card(
          elevation: 0, // Optional: Remove shadow if desired
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bankName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(bankDescription),
                          SizedBox(height: 8),
                          Text(loanRate),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Image.asset(
                      bankLogoAssetPath,
                      width: 60,
                      height: 60,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectBank(String bankName) {
    setState(() {
      _bankController.text = bankName;
    });
  }

  void _formatCurrency() {
    String text = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isNotEmpty) {
      String formattedAmount = _currencyFormatter.format(int.parse(text));
      _amountController.value = TextEditingValue(
        text: formattedAmount,
        selection: TextSelection.collapsed(offset: formattedAmount.length),
      );
    }
  }
}
