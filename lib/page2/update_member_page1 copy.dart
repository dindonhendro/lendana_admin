import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_io/io.dart';

class UpdateMemberPage extends StatefulWidget {
  final String id;
  final Function onMemberUpdated;

  UpdateMemberPage({required this.id, required this.onMemberUpdated});

  @override
  _UpdateMemberPageState createState() => _UpdateMemberPageState();
}

class _UpdateMemberPageState extends State<UpdateMemberPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _loanAmountController = TextEditingController();

  List<PlatformFile?> _images =
      List.filled(10, null); // For 10 different images
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberData(); // Fetch existing member data
  }

  // Fetch member data by ID and populate fields
  Future<void> _fetchMemberData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabaseClient
          .from('members')
          .select()
          .eq('id', widget.id)
          .single();

      if (response != null) {
        setState(() {
          _nameController.text = response['name'];
          _emailController.text = response['email'];
          _phoneController.text = response['phone'];
          _nikController.text = response['nik'];
          _dobController.text = response['dob'];
          _addressController.text = response['address'];
          _loanAmountController.text = response['loan_amount'].toString();

          // Load existing image URLs
          _images[0] =
              _createPlatformFileFromUrl(response['profile_image_url']);
          _images[1] =
              _createPlatformFileFromUrl(response['passport_image_url']);
          _images[2] =
              _createPlatformFileFromUrl(response['identity_image_url']);
          _images[3] = _createPlatformFileFromUrl(response['family_image_url']);
          _images[4] = _createPlatformFileFromUrl(response['doc1_image_url']);
          _images[5] = _createPlatformFileFromUrl(response['doc2_image_url']);
          _images[6] = _createPlatformFileFromUrl(response['doc3_image_url']);
          _images[7] = _createPlatformFileFromUrl(response['doc4_image_url']);
          _images[8] = _createPlatformFileFromUrl(response['doc5_image_url']);
          _images[9] = _createPlatformFileFromUrl(response['doc6_image_url']);
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching member data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Create a PlatformFile from a URL for displaying images
  PlatformFile? _createPlatformFileFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // You can use any name and bytes for the PlatformFile;
    // Just for preview purposes, we'll set dummy values here.
    return PlatformFile(
      name: url.split('/').last, // Extract file name from URL
      bytes: null, // No actual bytes here, just for representation
      size: 0, // Size can be set as 0, as we don't have it here
      path: url, // The URL is used as the path for displaying the image
    );
  }

  // Handle picking images
  Future<void> _pickImages(List<String> imageTypes) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        for (var i = 0; i < imageTypes.length; i++) {
          if (i < result.files.length) {
            _images[i] = result.files[i]; // Assign the selected images
          }
        }
      });
    }
  }

  // Update member information and upload images if changed
  Future<void> _updateMember() async {
    setState(() => _isLoading = true);
    try {
      List<String> imageUrls = await Future.wait(
        _images.map((image) {
          if (image != null && image.path != null && image.bytes != null) {
            return _uploadImage(image, 'doc1'); // Upload new image
          } else {
            return Future.value(''); // Keep the old image URL if not changed
          }
        }).toList(),
      );

      // Update the member information in the database
      final response = await _supabaseClient.from('members').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'nik': _nikController.text,
        'dob': _dobController.text,
        'address': _addressController.text,
        'loan_amount': _loanAmountController.text
            .replaceAll('Rp ', '')
            .replaceAll('.', ''),
        'profile_image_url': imageUrls[0].isNotEmpty
            ? imageUrls[0]
            : null, // Update if new image uploaded
        'passport_image_url': imageUrls[1].isNotEmpty ? imageUrls[1] : null,
        'identity_image_url': imageUrls[2].isNotEmpty ? imageUrls[2] : null,
        'family_image_url': imageUrls[3].isNotEmpty ? imageUrls[3] : null,
        'doc1_image_url': imageUrls[4].isNotEmpty ? imageUrls[4] : null,
        'doc2_image_url': imageUrls[5].isNotEmpty ? imageUrls[5] : null,
        'doc3_image_url': imageUrls[6].isNotEmpty ? imageUrls[6] : null,
        'doc4_image_url': imageUrls[7].isNotEmpty ? imageUrls[7] : null,
        'doc5_image_url': imageUrls[8].isNotEmpty ? imageUrls[8] : null,
        'doc6_image_url': imageUrls[9].isNotEmpty ? imageUrls[9] : null,
      }).eq('id', widget.id);

      if (response.error == null) {
        widget.onMemberUpdated();
        _showSnackBar('Member updated successfully!');
        Navigator.pop(context);
      } else {
        throw Exception(response.error!.message);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Member'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField('Name', _nameController),
                  _buildTextField('Name', _nameController),
                  _buildTextField('Phone', _phoneController),
                  _buildTextField('NIK', _nikController),
                  _buildTextField('Email', _emailController),
                  _buildTextField('Date of Birth (dd/mm/yyyy)', _dobController),
                  _buildTextField('Address', _addressController),
                  _buildTextField('Loan Amount', _loanAmountController),
                  ElevatedButton(
                    onPressed: () => _pickImages([
                      'Profile',
                      'Passport',
                      'Identity',
                      'Family',
                      'Doc1',
                      'Doc2',
                      'Doc3',
                      'Doc4',
                      'Doc5',
                      'Doc6'
                    ]),
                    child: Text('Select Images'),
                  ),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: List.generate(_images.length, (index) {
                      return _buildImagePreview(index);
                    }),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _updateMember, // Disable if loading
        child: Icon(Icons.save),
        tooltip: 'Save Changes',
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    return Column(
      children: [
        if (_images[index] != null)
          Image.network(
            _images[index]!.path ?? '', // Display existing image
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
        Text('Image ${index + 1}'),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
