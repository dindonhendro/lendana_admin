import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker instead of image_picker
import 'package:intl/intl.dart'; // For currency formatting
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart'; // Use universal_io instead of dart:io

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
  PlatformFile? _profileImage;
  PlatformFile? _passportImage;
  bool _isLoading = false;
  int _currentStep = 0;

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
  Future<void> _pickImage(bool isProfileImage) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        if (isProfileImage) {
          _profileImage = result.files.first;
        } else {
          _passportImage = result.files.first;
        }
      });
    }
  }

  // Save draft of the form
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
        'profile_image_url': _profileImage?.name,
        'passport_image_url': _passportImage?.name,
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

  // Submit form and upload images
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
            _buildImagePreview('Profile Image', _profileImage),
            _buildImagePickerButton(
                'Select Profile Image', () => _pickImage(true)),
            SizedBox(height: 10),
            _buildImagePreview('Passport Image', _passportImage),
            _buildImagePickerButton(
                'Select Passport Image', () => _pickImage(false)),
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

  // Build image preview widget
  Widget _buildImagePreview(String label, PlatformFile? image) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 8),
        image == null
            ? _buildImagePlaceholder('No image selected.')
            : Image.memory(image.bytes!,
                height: 100, width: 100, fit: BoxFit.cover),
      ],
    );
  }

  // Placeholder for image preview
  Widget _buildImagePlaceholder(String text) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(text)),
    );
  }

  // Build image picker button
  Widget _buildImagePickerButton(String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.image),
      label: Text(label),
    );
  }

  // Build action buttons (submit or save draft)
  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }

  // Build the main UI of the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Member')),
      body: Stepper(
        steps: _getSteps(),
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submitForm();
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
              if (_currentStep > 0)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              if (_currentStep < 2)
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: const Text('Next'),
                ),
            ],
          );
        },
      ),
    );
  }
}

// Custom date input formatter
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text.replaceAll(RegExp(r'[^0-9/]'), '');
    final chars = newText.split('');

    if (chars.length >= 5) {
      return TextEditingValue(
        text:
            '${chars[0]}${chars[1]}/${chars[2]}${chars[3]}/${newText.substring(4)}',
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } else if (chars.length >= 3) {
      return TextEditingValue(
        text: '${chars[0]}${chars[1]}/${newText.substring(2)}',
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } else {
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }
}
