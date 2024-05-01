import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  final String exerciseName;

  ExerciseTrackingScreen({required this.exerciseName});

  @override
  _ExerciseTrackingScreenState createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  TextEditingController weightController = TextEditingController();
  TextEditingController repsController = TextEditingController();
  bool showInputFields = false;
  List<String> weightRepsList = [];

  @override
  void initState() {
    super.initState();
    // Fetch data when the screen is initialized
    fetchData();
  }

  void fetchData() async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get a reference to the exercise node under the user's node
      DatabaseReference exerciseRef = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(user.uid)
          .child('exercises')
          .child(widget.exerciseName)
          .child('Data');

      // Listen for changes to the database reference
      exerciseRef.onValue.listen((event) {
        // Check if the widget is still mounted before updating the state
        if (mounted) {
          // Clear the existing list before adding fetched data
          setState(() {
            weightRepsList.clear();
          });

          // Extract data from the database event
          Map<dynamic, dynamic>? values = event.snapshot.value as Map<dynamic, dynamic>?;

          if (values != null) {
            // Extract entries with 'timestamp' field
            List<MapEntry<dynamic, dynamic>> entriesWithTimestamp = values.entries
                .where((entry) => entry.value['timestamp'] != null)
                .toList();

            // Sort entries based on 'timestamp' field
            entriesWithTimestamp.sort((a, b) {
              int timestampA = a.value['timestamp'];
              int timestampB = b.value['timestamp'];
              return timestampB.compareTo(timestampA);
            });

            // Add formatted data to the list
            entriesWithTimestamp.forEach((entry) {
              String weight = entry.value['weight'];
              String reps = entry.value['reps'];
              String date = entry.value['date'];
              String formattedData = '$weight x $reps $date';
              setState(() {
                weightRepsList.add(formattedData);
              });
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exerciseName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Toggle the visibility of input fields when the plus button is pressed
              setState(() {
                showInputFields = !showInputFields;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              thickness: 1,
              color: Colors.grey,
            ),
            if (showInputFields) ...[
              SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: InputDecoration(labelText: 'Enter Weight (lbs)'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              TextField(
                controller: repsController,
                decoration: InputDecoration(labelText: 'Enter Reps'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Add logic to save the weight, reps, and formatted date data
                  saveExerciseData();
                },
                child: Text('Add'),
              ),
            ],
            SizedBox(height: 16),
            Text(
              'Weight and Reps:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: weightRepsList.length,
                itemBuilder: (context, index) {
                  // Split the weight and reps data from the date
                  List<String> dataParts = weightRepsList[index].split(' ');
                  String weightReps = dataParts.getRange(0, dataParts.length - 1).join(' ');
                  String date = dataParts.last;
                  return ListTile(
                    title: Text(weightReps),
                    trailing: Text(
                      date,
                      textAlign: TextAlign.right, // Right justify the date
                      style: TextStyle(
                        fontSize: 14, // Adjust the font size as needed
                        color: Colors.grey, // Adjust the color as needed
                      ),
                    ),
                    // You can customize the appearance of each item as needed
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void saveExerciseData() async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Get a reference to the exercise node under the user's node
      DatabaseReference exerciseRef = FirebaseDatabase.instance
          .reference()
          .child('users')
          .child(user.uid)
          .child('exercises')
          .child(widget.exerciseName)
          .child('Data');

      // Save the weight, reps, date, and timestamp data to the database
      String currentDate = DateFormat('MM/dd/yyyy').format(DateTime.now());
      String weight = weightController.text;
      String reps = repsController.text;
      int timestamp = DateTime.now().millisecondsSinceEpoch; // Current timestamp
      Map<String, dynamic> data = {
        'weight': weight,
        'reps': reps,
        'date': currentDate,
        'timestamp': timestamp, // Add timestamp to the data
      };

      // Push the new data to the database
      exerciseRef.push().set(data);

      // Update the UI
      setState(() {
        weightController.clear();
        repsController.clear();
        showInputFields = false; // Hide the input fields after saving
      });
    }
  }
}
