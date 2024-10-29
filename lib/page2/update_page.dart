import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePage extends StatefulWidget {
  final String id; // The ID of the member to be updated
  final Function onMemberUpdated;

  UpdatePage({required this.id, required this.onMemberUpdated});

  @override
  _UpdatePageState createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  PlatformFile? _profileImage;
  PlatformFile? _passportImage;
  PlatformFile? _identityImage;
  PlatformFile? _familyImage;
  bool _isLoading = false;
  int _currentStep = 0;

  // Load existing member data
  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();

      if (response != null) {
        _nameController.text = response['name'];
        _emailController.text = response['email'];
        _phoneController.text = response['phone'];
        _nikController.text = response['nik'];
        _dobController.text = response['dob'];
        _addressController.text = response['address'];
        _loanAmountController.text =
            _formatCurrency(response['loan_amount'].toString());
      }
    } catch (e) {
      _showSnackBar('Error loading member data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Format the currency input
  String _formatCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String numericString = amount.replaceAll(RegExp(r'[^\d]'), '');
    if (numericString.isEmpty) return '';
    final numericAmount = int.tryParse(numericString);
    return numericAmount != null ? formatter.format(numericAmount) : amount;
  }

  // Handle loan amount change and format it
  void _onLoanAmountChanged(String value) {
    final formattedAmount = _formatCurrency(value);
    _loanAmountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );
  }

  // Pick image using file_picker
  Future<void> _pickImage(String imageType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        switch (imageType) {
          case 'profile':
            _profileImage = result.files.first;
            break;
          case 'passport':
            _passportImage = result.files.first;
            break;
          case 'identity':
            _identityImage = result.files.first;
            break;
          case 'family':
            _familyImage = result.files.first;
            break;
        }
      });
    }
  }

  // Submit form and upload images
  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _profileImage == null ||
        _passportImage == null ||
        _identityImage == null ||
        _familyImage == null) {
      _showSnackBar('Please complete all fields and upload all images.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profileImageUrl =
          await _uploadImage(_profileImage!, 'profile_images');
      final passportImageUrl =
          await _uploadImage(_passportImage!, 'passport_images');
      final identityImageUrl =
          await _uploadImage(_identityImage!, 'identity_image');
      final familyImageUrl = await _uploadImage(_familyImage!, 'family_image');

      final memberResponse = await _supabaseClient
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
            'profile_image_url': profileImageUrl,
            'passport_image_url': passportImageUrl,
            'identity_image_url': identityImageUrl,
            'family_image_url': familyImageUrl,
          })
          .eq('id', widget.id)
          .select();

      if (memberResponse.isEmpty) throw Exception('Error updating member.');

      widget.onMemberUpdated();
      _showSnackBar('Member updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Error updating member: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Upload image to Supabase storage
  Future<String> _uploadImage(PlatformFile file, String bucket) async {
    final uploadPath = 'public/${file.name}';
    await _supabaseClient.storage
        .from(bucket)
        .uploadBinary(uploadPath, file.bytes!);
    return _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);
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
                inputType: TextInputType.number,
                inputFormatter: [DateInputFormatter()]),
            _buildTextField('Address', _addressController),
            _buildTextField('Loan Amount', _loanAmountController,
                inputType: TextInputType.number,
                onChanged: _onLoanAmountChanged),
          ],
        ),
        isActive: _currentStep == 0,
      ),
      Step(
        title: Text('Upload Images'),
        content: Column(
          children: [
            _buildImagePickerButton(
                'Select Profile Image', () => _pickImage('profile')),
            SizedBox(height: 10),
            _buildImagePickerButton(
                'Select Passport Image', () => _pickImage('passport')),
            SizedBox(height: 10),
            _buildImagePickerButton(
                'Select Identity Image', () => _pickImage('identity')),
            SizedBox(height: 10),
            _buildImagePickerButton(
                'Select Family Image', () => _pickImage('family')),
          ],
        ),
        isActive: _currentStep == 1,
      ),
      Step(
        title: Text('Review & Submit'),
        content: Column(
          children: [
            Text('Review all the information before submission.'),
            SizedBox(height: 20),
            _buildActionButton('Update', _submitForm),
          ],
        ),
        isActive: _currentStep == 2,
      ),
    ];
  }

  // Build text field with custom styling
  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType inputType = TextInputType.text,
      List<TextInputFormatter>? inputFormatter,
      Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blueAccent)),
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
        keyboardType: inputType,
        inputFormatters: inputFormatter,
        onChanged: onChanged,
      ),
    );
  }

  // Build image picker button
  Widget _buildImagePickerButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }

  // Build action button
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Member')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() {
                _currentStep = step;
              }),
              onStepContinue: () {
                if (_currentStep < _getSteps().length - 1) {
                  setState(() => _currentStep++);
                } else {
                  _submitForm();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              steps: _getSteps(),
            ),
    );
  }
}

// Custom formatter for Date Input
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Handle date formatting
    return newValue;
  }
}
