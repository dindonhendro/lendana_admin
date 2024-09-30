import 'package:supabase_flutter/supabase_flutter.dart';

class SupaBaseHandler {
  static String supabaseUrl = 'https://diqmnwgzykbfkrnhsrva.supabase.co';
  static String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpcW1ud2d6eWtiZmtybmhzcnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjU5NDIzMzYsImV4cCI6MjA0MTUxODMzNn0.iECRGEBfku8lqlRI3q7SpInjxsLp1E7LbMUQGt3jPPw';

  final SupabaseClient client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  /// Add a new country to the 'job' table
  Future<void> addData(String country) async {
    try {
      final response =
          await client.from('job').insert({'country': country}).select();

      if (response != null) {
        print('Data added successfully: $response');
      }
    } catch (e) {
      print('Error adding data: $e');
    }
  }

  /// Read and fetch country data from the 'job' table
  Future<List<dynamic>> readData() async {
    try {
      final response =
          await client.from('job').select().order('country', ascending: true);

      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  /// Delete a job record based on the job id
  Future<void> deleteData(int jobId) async {
    try {
      final response = await client
          .from('job')
          .delete()
          .eq('id', jobId); // Deleting the record by its ID

      if (response != null) {
        print('Data deleted successfully: $response');
      } else {
        print('No data found to delete.');
      }
    } catch (e) {
      print('Error deleting data: $e');
    }
  }
}
