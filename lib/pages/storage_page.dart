import 'dart:io';
import '../components/storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final StorageService _storageService =
      StorageService(); // Instantiate the service
  List<String> _fileNames = []; // List to hold file names
  bool _isLoading = false; // To manage loading state

  // Function to get all files
  Future<void> _getAllFiles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fileNames = await _storageService.getAllFiles();
      setState(() {
        _fileNames = fileNames;
      });
    } catch (e) {
      print('Error fetching files: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to upload a file
  Future<void> _uploadFile() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _storageService.addFile(File(result.files.single.path!));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('File uploaded successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
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
        title: Text('Storage'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _getAllFiles, // Fetch all files
                  child: Text('Get All Files'),
                ),
                ElevatedButton(
                  onPressed: _uploadFile, // Upload file
                  child: Text('Upload File'),
                ),
              ],
            ),
            if (_isLoading)
              CircularProgressIndicator(), // Show loading indicator if needed
            ..._fileNames
                .map((fileName) => ListTile(
                      title: Text(fileName),
                    ))
                .toList(), // Display the list of file names
          ],
        ),
      ),
    );
  }
}
