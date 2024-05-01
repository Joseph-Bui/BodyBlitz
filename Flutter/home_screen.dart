import 'package:flutter/material.dart';
import 'exercise_entry_screen.dart';
import 'progress_tracker_screen.dart';
import 'exercise_tracking_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> exercises = [];

  @override
  void initState() {
    super.initState();
    // Fetch user's exercises when the screen loads
    fetchExercises();
  }

  // Method to fetch user's exercises from the database
  void fetchExercises() async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (user != null) {
      DatabaseReference exercisesRef =
      FirebaseDatabase.instance.reference().child('users').child(user.uid).child('exercises');

      // Listen for changes to the database reference
      exercisesRef.onValue.listen((event) {
        // Clear the existing list before adding fetched exercises
        setState(() {
          exercises.clear();
        });

        // Extract exercise names from the database event
        Map<dynamic, dynamic>? values = event.snapshot.value as Map<dynamic, dynamic>?;

        if (values != null) {
          values.forEach((key, value) {
            String exerciseName = key;
            exercises.add(exerciseName);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercises'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              var result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ExerciseEntryScreen()),
              );

              // Check if result is not null, is a String, and is not empty
              if (result != null && result is String && result.isNotEmpty) {
                // Update the exercises list
                setState(() {
                  exercises.add(result);
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              // Sign out the user
              await FirebaseAuth.instance.signOut();
              // Navigate to the login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Divider(
            thickness: 1,
            color: Colors.grey,
          ),
          // Display the exercises using a ListView.builder
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                return buildClickableExerciseItem(exercises[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildClickableExerciseItem(String exerciseName) {
    return GestureDetector(
      onTap: () {
        // Navigate to the ExerciseTrackingScreen when an exercise is clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseTrackingScreen(exerciseName: exerciseName),
          ),
        );
      },
      child: Dismissible(
        key: Key(exerciseName),
        onDismissed: (direction) async {
          // Remove the dismissed exercise from the list
          setState(() {
            exercises.remove(exerciseName);
          });

          // Delete the exercise from the database
          await deleteExerciseFromDatabase(exerciseName);

          // Show a snackbar after the exercise is deleted
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exercise \"$exerciseName\" deleted.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        child: ListTile(
          title: Text(exerciseName),
          // Add other ListTile properties as needed
        ),
      ),
    );
  }

  Future<void> deleteExerciseFromDatabase(String exerciseName) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference exerciseRef = FirebaseDatabase.instance.reference().child('users').child(user.uid).child('exercises').child(exerciseName);
      await exerciseRef.remove();
    }
  }
}