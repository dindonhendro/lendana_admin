import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'job_detail.dart'; // Import the JobDetail page

class JobList extends StatefulWidget {
  const JobList({super.key});

  @override
  State<JobList> createState() => _JobListState();
}

class _JobListState extends State<JobList> {
  String? selectedCountry; // Store selected country
  List<dynamic> jobs = [];
  List<String> countries = [
    'Hongkong',
    'Taiwan',
    'Korea',
    'Japan',
  ]; // List of countries to filter

  final _supabaseClient = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchJobs();
  }

  // Fetch all jobs initially or based on country filter
  Future<void> _fetchJobs([String? country]) async {
    setState(() {
      jobs = [];
    });

    try {
      var query = _supabaseClient.from('job').select();

      if (country != null && country.isNotEmpty) {
        query = query.eq('country', country);
      }

      final response = await query.order('country', ascending: true);

      setState(() {
        jobs = response as List<dynamic>;
      });
    } catch (e) {
      print('Error fetching jobs: $e');
    }
  }

  // Function to get the flag image path
  String getFlagImage(String country) {
    switch (country) {
      case 'Hongkong':
        return 'assets/flags/hongkong.png';
      case 'Taiwan':
        return 'assets/flags/taiwan.png';
      case 'Korea':
        return 'assets/flags/korea.png';
      case 'Japan':
        return 'assets/flags/japan.png';
      default:
        return 'assets/flags/default.png'; // Provide a default image
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Find Your Dream Job',
              style: TextStyle(
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              'Search your job in different countries',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Country Dropdown
            DropdownButton<String>(
              value: selectedCountry,
              hint: Text('Select a country'),
              items: countries.map((String country) {
                return DropdownMenuItem<String>(
                  value: country,
                  child: Text(country),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                });
                // Fetch jobs based on selected country
                _fetchJobs(value);
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: jobs.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to JobDetail page with the selected job
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      JobDetail(job: jobs[index]),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 2.0,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            jobs[index]['role'],
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Company: ${jobs[index]['company']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Country: ${jobs[index]['country']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Salary: ${jobs[index]['salary']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Flag image on the right
                                    Image.asset(
                                      getFlagImage(jobs[index]['country']),
                                      width: 40,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
