import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart'; // Use file_picker instead of image_picker
import 'package:intl/intl.dart'; // For currency formatting
import 'package:lendana_admin/components/card_service.dart';
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
  PlatformFile? _identityImage;
  PlatformFile? _familyImage;
  PlatformFile? _doc1Image;
  PlatformFile? _doc2Image;
  PlatformFile? _doc3Image;
  PlatformFile? _doc4Image;
  PlatformFile? _doc5Image;
  PlatformFile? _doc6Image;
  PlatformFile? _doc7Image;
  PlatformFile? _doc8Image;
  PlatformFile? _doc9Image;
  PlatformFile? _doc10Image;

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
          case 'doc1':
            _doc1Image = result.files.first;
            break;
          case 'doc2':
            _doc2Image = result.files.first;
            break;
          case 'doc3':
            _doc3Image = result.files.first;
            break;
          case 'doc4':
            _doc4Image = result.files.first;
            break;
          case 'doc5':
            _doc5Image = result.files.first;
            break;
          case 'doc6':
            _doc6Image = result.files.first;
            break;
          case 'doc7':
            _doc7Image = result.files.first;
            break;
          case 'doc8':
            _doc8Image = result.files.first;
            break;
          case 'doc9':
            _doc9Image = result.files.first;
            break;
          case 'doc10':
            _doc10Image = result.files.first;
            break;
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
      final userId = _supabaseClient.auth.currentUser?.id;
      final profileImageUrl =
          await _uploadImage(_profileImage!, 'profile_images');
      final passportImageUrl =
          await _uploadImage(_passportImage!, 'passport_images');
      final identityImageUrl =
          await _uploadImage(_identityImage!, 'identity_image');
      final familyImageUrl = await _uploadImage(_familyImage!, 'family_image');
      final doc1ImageUrl = await _uploadImage(_doc1Image!, 'doc1');
      final doc2ImageUrl = await _uploadImage(_doc2Image!, 'doc2');
      final doc3ImageUrl = await _uploadImage(_doc3Image!, 'doc3');
      final doc4ImageUrl = await _uploadImage(_doc4Image!, 'doc4');
      final doc5ImageUrl = await _uploadImage(_doc5Image!, 'doc5');
      final doc6ImageUrl = await _uploadImage(_doc6Image!, 'doc6');
      final doc7ImageUrl = await _uploadImage(_doc7Image!, 'doc7');
      final doc8ImageUrl = await _uploadImage(_doc8Image!, 'doc8');
      final doc9ImageUrl = await _uploadImage(_doc9Image!, 'doc9');
      final doc10ImageUrl = await _uploadImage(_doc10Image!, 'doc10');

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
        'identity_image_url': identityImageUrl,
        'family_image_url': familyImageUrl,
        'doc1_image_url': doc1ImageUrl,
        'doc2_image_url': doc2ImageUrl,
        'doc3_image_url': doc3ImageUrl,
        'doc4_image_url': doc4ImageUrl,
        'doc5_image_url': doc5ImageUrl,
        'doc6_image_url': doc6ImageUrl,
        'doc7_image_url': doc7ImageUrl,
        'doc8_image_url': doc8ImageUrl,
        'doc9_image_url': doc9ImageUrl,
        'doc10_image_url': doc10ImageUrl,
        'is_approved': false,
        'admin_id': userId,
      }).select();

      if (memberResponse.isEmpty) throw Exception('Error adding member.');

      final memberId = memberResponse.first['id'];
      final loanResponse =
          await _supabaseClient.from('loan_applications').insert({
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
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
        content: Wrap(
          spacing: 20, // Horizontal spacing between items
          runSpacing: 20, // Vertical spacing between rows
          children: [
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Profile Image', _profileImage),
                  _buildImagePickerButton(
                      'Select Profile Image', () => _pickImage('profile')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Passport Image', _passportImage),
                  _buildImagePickerButton(
                      'Select Passport Image', () => _pickImage('passport')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Identity Image', _identityImage),
                  _buildImagePickerButton(
                      'Select Identity Image', () => _pickImage('identity')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Family Image', _familyImage),
                  _buildImagePickerButton(
                      'Select Family Image', () => _pickImage('family')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc1 Image', _doc1Image),
                  _buildImagePickerButton(
                      'Select Doc1 Image', () => _pickImage('doc1')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc2 Image', _doc2Image),
                  _buildImagePickerButton(
                      'Select Doc2 Image', () => _pickImage('doc2')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc3 Image', _doc2Image),
                  _buildImagePickerButton(
                      'Select Doc3 Image', () => _pickImage('doc3')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc4 Image', _doc4Image),
                  _buildImagePickerButton(
                      'Select Doc4 Image', () => _pickImage('doc4')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc5 Image', _doc5Image),
                  _buildImagePickerButton(
                      'Select Doc5 Image', () => _pickImage('doc5')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc6 Image', _doc6Image),
                  _buildImagePickerButton(
                      'Select Doc6 Image', () => _pickImage('doc6')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc7 Image', _doc7Image),
                  _buildImagePickerButton(
                      'Select Doc7 Image', () => _pickImage('doc7')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc8 Image', _doc8Image),
                  _buildImagePickerButton(
                      'Select Doc8 Image', () => _pickImage('doc8')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc9 Image', _doc9Image),
                  _buildImagePickerButton(
                      'Select Doc9 Image', () => _pickImage('doc9')),
                ],
              ),
            ),
            Container(
              width: 300, // Fixed width to ensure 2 items in a row
              child: Column(
                children: [
                  _buildImagePreview('Doc10 Image', _doc10Image),
                  _buildImagePickerButton(
                      'Select Doc10 Image', () => _pickImage('doc10')),
                ],
              ),
            ),

            // Add other document previews similarly...
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
