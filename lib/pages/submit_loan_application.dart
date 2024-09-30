import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> submitLoanApplication(Map<String, dynamic> loanData) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId != null) {
    final response = await supabase.from('loan_applications').insert({
      'loan_amount': 10000,
      'interest_rate': 5.5,
      'loan_status': 'Pending',
      'user_id': userId, // Linking the loan application with the user
    });

    if (response.error == null) {
      print('Loan application submitted successfully');
    } else {
      print('Error submitting loan application: ${response.error!.message}');
    }
  }
}
