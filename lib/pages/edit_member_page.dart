import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMemberPage extends StatefulWidget {
  final String id;
  final Function onMemberUpdated;

  const EditMemberPage({
    Key? key,
    required this.id, // Ensure the id parameter is required
    required this.onMemberUpdated,
  }) : super(key: key);

  @override
  _EditMemberPageState createState() => _EditMemberPageState();
}

class _EditMemberPageState extends State<EditMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadMemberData(); // Load existing member data
  }

  // Load member data from Supabase
  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    try {
      // Fetching member data based on member ID
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();

      // Check if the response contains any data
      if (response.isEmpty) {
        _showSnackBar('No member found with the given ID.');
        return;
      }

      // Access the member data directly from response
      final member = response;

      // Populate text fields with member data
      _nameController.text = member['name'] ?? '';
      _emailController.text = member['email'] ?? '';
      _phoneController.text = member['phone'] ?? '';
      _nikController.text = member['nik'] ?? '';
      _dobController.text = member['dob'] ?? '';
      _addressController.text = member['address'] ?? '';
      _loanAmountController.text =
          _formatCurrency(member['loan_amount'] ?? '0');
    } catch (e) {
      // Handle any unexpected errors
      _showSnackBar('Error loading member data: ${e.toString()}');
    } finally {
      // Always set loading to false
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMember() async {
    try {
      final response = await _supabaseClient
          .from('members')
          .update({
            'name': _nameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'nik': _nikController.text,
            'dob': _dobController.text,
            'address': _addressController.text,
            'loan_amount': _loanAmountController.text
                .replaceAll('Rp ', '')
                .replaceAll('.', ''),
          })
          .eq('id', widget.id)
          .select();

      print('Update Response: $response');

      if (response.isEmpty) {
        throw Exception('Error updating member: ${response}');
      } else if (response.isEmpty) {
        throw Exception('No rows were updated. Check if the ID is correct.');
      } else {
        print('Member updated successfully.');
      }
    } catch (e) {
      print('Exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating member: ${e.toString()}')),
      );
    }
  }

  // Show a snackbar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Define steps for the Stepper widget
  List<Step> _getSteps() {
    return [
      Step(
        title: Text('Member Info'),
        content: Column(
          children: [
            _buildTextField('Name', _nameController),
            _buildTextField('Phone', _phoneController),
            _buildTextField('NIK', _nikController),
            _buildTextField('Email', _emailController),
            _buildTextField('Date of Birth (dd/mm/yyyy)', _dobController,
                inputType: TextInputType.datetime),
            _buildTextField('Address', _addressController),
            _buildTextField('Loan Amount', _loanAmountController,
                inputType: TextInputType.number,
                onChanged: _onLoanAmountChanged),
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Review & Submit'),
        content: Column(
          children: [
            Text('Review all the information before submission.'),
            SizedBox(height: 20),
            _buildActionButton('Update', _updateMember),
          ],
        ),
        isActive: _currentStep == 1,
      ),
    ];
  }

  // Utility method to build a text field
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text,
      Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: inputType,
      onChanged: onChanged,
    );
  }

  // Utility method to build an action button
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // Handle loan amount change and format it
  void _onLoanAmountChanged(String value) {
    final formattedAmount = _formatCurrency(value);
    _loanAmountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );
  }

  String _formatCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String numericString = amount.replaceAll(RegExp(r'[^\d]'), '');
    if (numericString.isEmpty) return '';
    final numericAmount = int.tryParse(numericString);
    return numericAmount != null ? formatter.format(numericAmount) : amount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Member')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
              steps: _getSteps(),
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 1) {
                  setState(() => _currentStep += 1);
                } else {
                  _updateMember();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: details.onStepCancel,
                      child: Text('Back'),
                    ),
                    ElevatedButton(
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 1 ? 'Submit' : 'Next'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
