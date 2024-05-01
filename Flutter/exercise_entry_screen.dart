import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseEntryScreen extends StatelessWidget {
  TextEditingController _exerciseNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Exercise'),
        actions: [
          IconButton(
            icon: Icon(Icons.done),
            onPressed: () async {
              // Send exercise name to the Realtime Database
              String exerciseName = _exerciseNameController.text;
              addExerciseToDatabase(exerciseName);
              // Close the screen
              Navigator.pop(context, exerciseName);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Name',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _exerciseNameController,
              decoration: InputDecoration(
                hintText: 'Enter exercise name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addExerciseToDatabase(String exerciseName) async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get a reference to the Realtime Database root
      DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users').child(user.uid);

      // Set the exercise name as the key in the exercises node
      userRef.child('exercises').child(exerciseName).set({'name': exerciseName});
    } else {
      print('User not authenticated.');
    }
  }
}
