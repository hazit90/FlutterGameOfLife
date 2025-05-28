import 'package:flutter/material.dart';
import 'package:game_of_life/computers/gol_computer.dart';
import 'package:game_of_life/screens/game_screen.dart';
import 'package:game_of_life/data/update_type.dart';

/// Default value for rows and columns input fields
const String _defaultGridSize = '1000';

/// Maximum allowed value for grid dimensions
const int _maxGridSize = 1000;

/// Welcome screen that allows users to configure Game of Life parameters
///
/// This screen provides:
/// - Input fields for grid dimensions (rows and columns)
/// - Dropdown to select update algorithm type (filtered by platform support)
/// - Validation for user inputs
/// - Navigation to the game screen
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// Controller for the rows input field
  late final TextEditingController _rowsController;

  /// Controller for the columns input field
  late final TextEditingController _colsController;

  /// Currently selected update algorithm type
  late UpdateType _selectedUpdateType;

  /// List of update types supported on the current platform
  late final List<UpdateType> _supportedUpdateTypes;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with default values
    _rowsController = TextEditingController(text: _defaultGridSize);
    _colsController = TextEditingController(text: _defaultGridSize);

    // Get supported update types for the current platform
    _supportedUpdateTypes = GolComputer.getSupportedUpdateTypes();

    // Set default selection to the first supported type, or flutter as fallback
    _selectedUpdateType = _supportedUpdateTypes.isNotEmpty
        ? _supportedUpdateTypes.first
        : UpdateType.flutter;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Game of Life'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRowsInputField(),
            const SizedBox(height: 24),
            _buildColumnsInputField(),
            const SizedBox(height: 16),
            _buildUpdateTypeDropdown(),
            const SizedBox(height: 24),
            _buildStartButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the input field for number of rows
  Widget _buildRowsInputField() {
    return TextField(
      controller: _rowsController,
      decoration: const InputDecoration(
        labelText: 'Enter number of rows',
        border: OutlineInputBorder(),
        helperText: 'Maximum: $_maxGridSize',
      ),
      keyboardType: TextInputType.number,
    );
  }

  /// Builds the input field for number of columns
  Widget _buildColumnsInputField() {
    return TextField(
      controller: _colsController,
      decoration: const InputDecoration(
        labelText: 'Enter number of columns',
        border: OutlineInputBorder(),
        helperText: 'Maximum: $_maxGridSize',
      ),
      keyboardType: TextInputType.number,
    );
  }

  /// Builds the dropdown for selecting update algorithm type
  /// Only shows update types that are supported on the current platform
  Widget _buildUpdateTypeDropdown() {
    return Row(
      children: [
        const Text(
          'Update Algorithm: ',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButton<UpdateType>(
            value: _selectedUpdateType,
            isExpanded: true,
            onChanged: _onUpdateTypeChanged,
            items: _supportedUpdateTypes.map(_buildDropdownItem).toList(),
          ),
        ),
      ],
    );
  }

  /// Builds individual dropdown menu items
  DropdownMenuItem<UpdateType> _buildDropdownItem(UpdateType value) {
    return DropdownMenuItem<UpdateType>(
      value: value,
      child: Text(_getUpdateTypeDisplayName(value)),
    );
  }

  /// Gets a user-friendly display name for the update type
  String _getUpdateTypeDisplayName(UpdateType updateType) {
    switch (updateType) {
      case UpdateType.flutter:
        return 'Dart/Flutter';
      case UpdateType.cpp:
        return 'C++';
      case UpdateType.cppThreads:
        return 'C++ (Multi-threaded)';
      case UpdateType.metal:
        return 'Metal (GPU)';
      case UpdateType.golang:
        return 'Go';
      case UpdateType.golangThreads:
        return 'Go (Multi-threaded)';
    }
  }

  /// Builds the start game button
  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Start Game',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  /// Handles changes to the update type dropdown
  void _onUpdateTypeChanged(UpdateType? newValue) {
    if (newValue != null && _supportedUpdateTypes.contains(newValue)) {
      setState(() {
        _selectedUpdateType = newValue;
      });
    }
  }

  /// Validates input and starts the game if all inputs are valid
  void _startGame() {
    final int rows = int.tryParse(_rowsController.text) ?? 0;
    final int cols = int.tryParse(_colsController.text) ?? 0;

    // Validate maximum input values
    if (_isInputTooLarge(rows, cols)) {
      _showMaxInputExceededDialog();
      return;
    }

    // Validate positive input values
    if (_isInputInvalid(rows, cols)) {
      _showInvalidInputDialog();
      return;
    }

    // Double-check that the selected update type is still supported
    if (!GolComputer.isUpdateTypeSupported(_selectedUpdateType)) {
      _showUnsupportedUpdateTypeDialog();
      return;
    }

    // Navigate to game screen with validated parameters
    _navigateToGameScreen(rows, cols);
  }

  /// Checks if input values exceed maximum allowed size
  bool _isInputTooLarge(int rows, int cols) {
    return rows > _maxGridSize || cols > _maxGridSize;
  }

  /// Checks if input values are invalid (non-positive)
  bool _isInputInvalid(int rows, int cols) {
    return rows <= 0 || cols <= 0;
  }

  /// Shows dialog when input exceeds maximum allowed values
  void _showMaxInputExceededDialog() {
    _showErrorDialog(
      title: 'Input Too Large',
      message:
          'Please enter row and column values less than or equal to $_maxGridSize.',
    );
  }

  /// Shows dialog when input values are invalid
  void _showInvalidInputDialog() {
    _showErrorDialog(
      title: 'Invalid Input',
      message: 'Please enter positive numbers for both rows and columns.',
    );
  }

  /// Shows dialog when selected update type is not supported
  void _showUnsupportedUpdateTypeDialog() {
    _showErrorDialog(
      title: 'Unsupported Algorithm',
      message:
          'The selected update algorithm is not supported on this platform.',
    );
  }

  /// Shows a generic error dialog with custom title and message
  void _showErrorDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Navigates to the game screen with the specified parameters
  void _navigateToGameScreen(int rows, int cols) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
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
    // Clean up controllers to prevent memory leaks
    _rowsController.dispose();
    _colsController.dispose();
    super.dispose();
  }
}
