import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:path/path.dart'; // Import for basename

class StorageService {
  late SupabaseClient client;

  StorageService() {
    client = Supabase.instance.client;
  }

  // Fetch all files from the 'images' bucket
  Future<List<String>> getAllFiles() async {
    List<String> fileNames = [];

    try {
      var response =
          await client.storage.from('images').list(); // Corrected bucket name
      for (var e in response) {
        if (e.name != ".emptyFolderPlaceholder") {
          fileNames.add(e.name);
        }
      }
      print(fileNames);
    } catch (e) {
      print('Error fetching files: $e');
    }

    return fileNames;
  }

  // Upload a file to the 'images' bucket
  Future<void> addFile(File file) async {
    try {
      var res = await client.storage
          .from('images')
          .upload(basename(file.path), file); // basename needs 'path' package
      print(res);
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  // Download a file from the 'images' bucket
  Future<Uint8List> downloadFile(String fileName) async {
    try {
      print(fileName);
      final Uint8List bytes =
          await client.storage.from('images').download(fileName);
      return bytes;
    } catch (e) {
      print('Error downloading file: $e');
      return Uint8List(0); // Return an empty byte array in case of error
    }
  }
}
