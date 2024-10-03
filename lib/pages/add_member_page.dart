import 'dart:io'; // For handling files
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // For currency formatting
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMemberPage extends StatefulWidget {
  final Function onMemberAdded;

  AddMemberPage({required this.onMemberAdded});

  @override
  _AddMemberPageState createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();
  XFile? _profileImage;
  XFile? _passportImage;
  bool _isLoading = false;
  int _currentStep = 0;

  String _formatCurrency(String amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    String numericString = amount.replaceAll(RegExp(r'[^\d]'), '');
    if (numericString.isEmpty) return '';
    final numericAmount = int.tryParse(numericString);
    return numericAmount != null ? formatter.format(numericAmount) : amount;
  }

  void _onLoanAmountChanged(String value) {
    final formattedAmount = _formatCurrency(value);
    _loanAmountController.value = TextEditingValue(
      text: formattedAmount,
      selection: TextSelection.collapsed(offset: formattedAmount.length),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isProfileImage) async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage = await _picker.pickImage(source: source);
    setState(() {
      if (isProfileImage) {
        _profileImage = selectedImage;
      } else {
        _passportImage = selectedImage;
      }
    });
  }

  Future<void> _saveDraft() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      _showSnackBar('Please complete all required fields before saving.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabaseClient.from('drafts').insert({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'profile_image_url': _profileImage?.path,
        'passport_image_url': _passportImage?.path,
        'is_submitted': false,
      }).select();

      if (response.isNotEmpty) {
        _showSnackBar('Draft saved successfully!');
      }
    } catch (e) {
      _showSnackBar('Error saving draft: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitForm() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _profileImage == null ||
        _passportImage == null) {
      _showSnackBar('Please complete all fields and upload both images.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final profileImageUrl =
          await _uploadImage(_profileImage!, 'profile_images');
      final passportImageUrl =
          await _uploadImage(_passportImage!, 'passport_images');

      final memberResponse = await _supabaseClient.from('members').insert({
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
        'is_approved': false,
      }).select();

      if (memberResponse.isEmpty) throw Exception('Error adding member.');

      final memberId = memberResponse.first['id'];
      final loanResponse =
          await _supabaseClient.from('loan_applications').insert({
        'member_id': memberId,
        'status': 'pending',
        'reviewed_by': null,
      }).select();

      if (loanResponse.isNotEmpty) {
        widget.onMemberAdded();
        _showSnackBar('Loan application submitted successfully!');
        Navigator.pop(context);
      } else {
        throw Exception('Error creating loan application.');
      }
    } catch (e) {
      _showSnackBar('Error adding member and loan application: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadImage(XFile image, String bucket) async {
    final file = File(image.path);
    final uploadPath = 'public/${image.name}';
    await _supabaseClient.storage.from(bucket).upload(uploadPath, file);
    return _supabaseClient.storage.from(bucket).getPublicUrl(uploadPath);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

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
            _buildImagePreview('Profile Image', _profileImage),
            _buildImagePickerButton('Select Profile Image',
                () => _pickImage(ImageSource.gallery, true)),
            SizedBox(height: 10),
            _buildImagePreview('Passport Image', _passportImage),
            _buildImagePickerButton('Select Passport Image',
                () => _pickImage(ImageSource.gallery, false)),
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
            _buildActionButton('Submit', _submitForm),
            _buildActionButton('Save Draft', _saveDraft),
          ],
        ),
        isActive: _currentStep == 2,
      ),
    ];
  }

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

  Widget _buildImagePreview(String label, XFile? image) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 8),
        image == null
            ? _buildImagePlaceholder('No image selected.')
            : Image.file(File(image.path),
                height: 100, width: 100, fit: BoxFit.cover),
      ],
    );
  }

  Widget _buildImagePlaceholder(String text) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Center(child: Text(text, style: TextStyle(color: Colors.grey))),
    );
  }

  Widget _buildImagePickerButton(
      String text, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(text),
    );
  }

  Widget _buildActionButton(String text, Future<void> Function() onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Member')),
      body: Stepper(
        currentStep: _currentStep,
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
      floatingActionButton: _isLoading ? CircularProgressIndicator() : null,
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove all non-numeric characters
    String formattedText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Add slashes after the second and fourth digits
    if (formattedText.length >= 2) {
      formattedText = formattedText.replaceRange(2, 2, '/');
    }
    if (formattedText.length >= 5) {
      formattedText = formattedText.replaceRange(5, 5, '/');
    }

    // Ensure the cursor is positioned at the end of the text
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
