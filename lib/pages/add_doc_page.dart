import 'dart:io'; // For handling files
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDocPage extends StatefulWidget {
  final Function onDocAdded;
  AddDocPage({required this.onDocAdded});

  @override
  _AddDocPageState createState() => _AddDocPageState();
}

class _AddDocPageState extends State<AddDocPage> {
  final _supabaseClient = Supabase.instance.client;
  final TextEditingController _memberIdController = TextEditingController();
  XFile? _passportImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? selectedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _passportImage = selectedImage;
    });
  }

  Future<void> _submitForm() async {
    if (_memberIdController.text.isEmpty || _passportImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please provide member ID and upload a passport image.'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Upload the passport image to Supabase storage
      final file =
          File(_passportImage!.path); // Create a File object from the path

      // Ensure the upload directory and filename are correct
      final uploadPath = 'public/passport_images/${_passportImage!.name}';
      await _supabaseClient.storage
          .from('passport_images')
          .upload(uploadPath, file);

      // Get the public URL of the uploaded image
      final passportImageUrl = _supabaseClient.storage
          .from('passport_images')
          .getPublicUrl(uploadPath);

      // Step 2: Insert the passport image URL into the 'members' table
      final response = await _supabaseClient
          .from('members')
          .update({
            'passport_image_url': passportImageUrl,
          })
          .eq('id', _memberIdController.text)
          .select();

      if (response.isNotEmpty) {
        widget.onDocAdded(); // Refresh the document list
        Navigator.pop(context); // Go back after successful upload
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Passport image uploaded successfully!'),
        ));
      } else {
        throw Exception('Error updating member with passport image.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error uploading passport image: $e'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Passport Image')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _memberIdController,
                      decoration: InputDecoration(
                        labelText: 'Member ID',
                        hintText: 'Enter the member ID',
                      ),
                    ),
                    SizedBox(height: 10),
                    _passportImage == null
                        ? Text('No image selected.')
                        : Image.file(
                            File(_passportImage!.path)), // Display image
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Select Passport Image'),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _submitForm, // Submit the passport image
                      child: Text('Upload Passport Image'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
