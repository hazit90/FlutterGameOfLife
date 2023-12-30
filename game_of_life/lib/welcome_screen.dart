import 'package:flutter/material.dart';
import 'package:game_of_life/game_screen.dart';
import 'package:game_of_life/update_type.dart';

// ignore: non_constant_identifier_names
String rows_cols = '1000';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _rowsController =
      TextEditingController(text: rows_cols);
  final TextEditingController _colsController =
      TextEditingController(text: rows_cols);
  UpdateType _selectedUpdateType = UpdateType.metal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Game of Life')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _rowsController,
              decoration:
                  const InputDecoration(labelText: 'Enter number of rows'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _colsController,
              decoration:
                  const InputDecoration(labelText: 'Enter number of columns'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            DropdownButton<UpdateType>(
              value: _selectedUpdateType,
              onChanged: (UpdateType? newValue) {
                setState(() {
                  _selectedUpdateType = newValue!;
                });
              },
              items: UpdateType.values
                  .map<DropdownMenuItem<UpdateType>>((UpdateType value) {
                return DropdownMenuItem<UpdateType>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),

            ElevatedButton(
              onPressed: _startGame,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame() {
    // Parse the input values

    final int rows = int.tryParse(_rowsController.text) ?? 0;
    final int cols = int.tryParse(_colsController.text) ?? 0;

    // check max input
    int maxInput = 1000;
    if (rows > maxInput || cols > maxInput) {
      // Show an error message if the input is not valid
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Input'),
            content: const Text(
                'Please input row or column value of less than 1000.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Validate the input
    if (rows <= 0 || cols <= 0) {
      // Show an error message if the input is not valid
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Invalid Input'),
            content: const Text(
                'Please enter a positive number for rows and columns.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Navigate to the Game Screen with selected UpdateType
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => GameScreen(
        rows: rows,
        columns: cols,
        updateType: _selectedUpdateType,
      ),
    ),
  );
  }

  @override
  void dispose() {
    _rowsController.dispose();
    _colsController.dispose();
    super.dispose();
  }
}
