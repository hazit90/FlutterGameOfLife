import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:game_of_life/data/update_type.dart';

/// A 2D grid data structure that supports both Flutter-native and FFI implementations.
///
/// This class provides a unified interface for managing a 2D grid of floating-point values,
/// with the ability to switch between pure Dart implementation (Flutter) and native FFI
/// implementations for performance-critical operations.
///
/// Example usage:
/// ```dart
/// // Create a Flutter-based grid
/// final flutterGrid = Grid2D(10, 10, UpdateType.flutter, initRandom: true);
///
/// // Create an FFI-based grid
/// final ffiGrid = Grid2D(10, 10, UpdateType.cpp, initRandom: false);
///
/// // Access elements
/// flutterGrid[5] = 1.0;
/// double value = ffiGrid[3];
///
/// // Clean up resources
/// ffiGrid.dispose();
/// ```
class Grid2D {
  /// Pointer to native memory for FFI implementations.
  /// Used for all non-Flutter update types (cpp, cppThreads, metal, golang, golangThreads).
  late Pointer<Float> dataPointer;

  /// Number of rows in the grid.
  late int rows;

  /// Number of columns in the grid.
  late int columns;

  /// Random number generator for grid initialization.
  final random = Random();

  /// Finalizer to automatically clean up native memory when the object is garbage collected.
  /// This provides a safety net in case [dispose] is not called manually.
  final Finalizer<Pointer<Float>> _finalizer;

  /// Flag to track if the native memory has been manually disposed.
  /// Prevents double-free errors and ensures safe cleanup.
  bool _isDisposed = false;

  /// The implementation type for this grid (Flutter or any FFI-based type).
  UpdateType updateType;

  /// Dart-native float list for Flutter implementation.
  /// Only used when [updateType] is [UpdateType.flutter].
  late Float32List dataFloatList;

  /// Returns true if this update type uses FFI (native code).
  ///
  /// All update types except Flutter use FFI and require native memory management.
  bool get _isFFIBased => updateType != UpdateType.flutter;

  /// Returns the grid data as a [Float32List].
  ///
  /// For Flutter implementation, returns the internal [dataFloatList].
  /// For FFI implementations, converts the native pointer to a typed list.
  Float32List get data {
    if (updateType == UpdateType.flutter) {
      return dataFloatList;
    }
    return toFloat32List();
  }

  /// Accesses a grid element by linear index.
  ///
  /// The linear index is calculated as: `row * columns + column`.
  ///
  /// Parameters:
  /// - [idx]: The linear index of the element to access.
  ///
  /// Returns the value at the specified index.
  ///
  /// Throws [RangeError] if [idx] is out of bounds.
  /// Throws [StateError] if accessing a disposed grid.
  operator [](int idx) {
    if (_isDisposed) {
      throw StateError('Cannot access data of a disposed grid');
    }

    if (updateType == UpdateType.flutter) {
      return dataFloatList[idx];
    }
    return dataPointer[idx];
  }

  /// Sets a grid element by linear index.
  ///
  /// The linear index is calculated as: `row * columns + column`.
  ///
  /// Parameters:
  /// - [idx]: The linear index of the element to set.
  /// - [value]: The new value to assign.
  ///
  /// Throws [RangeError] if [idx] is out of bounds.
  /// Throws [StateError] if accessing a disposed grid.
  operator []=(int idx, double value) {
    if (_isDisposed) {
      throw StateError('Cannot access data of a disposed grid');
    }

    if (updateType == UpdateType.flutter) {
      dataFloatList[idx] = value;
      return;
    }
    dataPointer[idx] = value;
  }

  /// Creates a new 2D grid with the specified dimensions and implementation type.
  ///
  /// Parameters:
  /// - [rows]: The number of rows in the grid. Must be positive.
  /// - [columns]: The number of columns in the grid. Must be positive.
  /// - [updateType]: The implementation type (Flutter or any FFI-based type).
  /// - [initRandom]: Whether to initialize the grid with random values (0.0 or 1.0).
  ///   Defaults to false, which initializes all values to 0.0.
  ///
  /// For FFI implementations, allocates native memory that must be freed by calling [dispose].
  /// The finalizer provides automatic cleanup as a safety net, but manual disposal is recommended.
  ///
  /// Throws [ArgumentError] if [rows] or [columns] are not positive.
  Grid2D(this.rows, this.columns, this.updateType, {bool initRandom = false})
      : _finalizer = Finalizer<Pointer<Float>>(malloc.free) {
    // Validate input parameters
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Rows and columns must be positive integers');
    }

    if (updateType == UpdateType.flutter) {
      // Initialize Flutter-native implementation
      if (initRandom) {
        dataFloatList = Float32List.fromList(List.generate(
            rows * columns, (_) => random.nextBool() ? 1.0 : 0.0));
      } else {
        dataFloatList = Float32List(rows * columns);
      }
      return;
    }

    if (_isFFIBased) {
      // Initialize FFI implementation
      // Allocate native memory for the grid data
      dataPointer = malloc.allocate<Float>(sizeOf<Float>() * rows * columns);

      // Attach finalizer for automatic cleanup
      _finalizer.attach(this, dataPointer, detach: this);

      if (initRandom) {
        _initializeGridRandomly();
      }
    }
  }

  /// Clears the grid by setting all elements to 0.0.
  ///
  /// This method works for both Flutter and FFI implementations.
  ///
  /// Throws [StateError] if called on a disposed grid.
  void clear() {
    if (_isDisposed) {
      throw StateError('Cannot clear a disposed grid');
    }

    if (updateType == UpdateType.flutter) {
      // More efficient way to clear the list
      dataFloatList.fillRange(0, dataFloatList.length, 0.0);
    } else {
      // For FFI implementations
      final totalElements = rows * columns;
      for (int i = 0; i < totalElements; i++) {
        dataPointer[i] = 0.0;
      }
    }
  }

  /// Initializes the grid with random values (0.0 or 1.0).
  ///
  /// This is a private helper method used during construction when [initRandom] is true.
  /// Each cell has a 50% chance of being set to 1.0, otherwise it's set to 0.0.
  ///
  /// Throws [StateError] if called on a disposed grid.
  void _initializeGridRandomly() {
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed grid');
    }

    for (int i = 0; i < rows * columns; i++) {
      this[i] = random.nextBool() ? 1.0 : 0.0;
    }
  }

  /// Converts the native pointer data to a [Float32List].
  ///
  /// This method is only applicable for FFI implementations.
  /// It creates a view of the native memory without copying the data.
  ///
  /// Returns a [Float32List] that directly maps to the native memory.
  ///
  /// Throws [StateError] if called on a disposed grid or Flutter implementation.
  Float32List toFloat32List() {
    if (updateType == UpdateType.flutter) {
      throw StateError(
          'toFloat32List() should not be called on Flutter implementation');
    }
    if (_isDisposed) {
      throw StateError('Cannot access data of a disposed grid');
    }
    return dataPointer.asTypedList(rows * columns);
  }

  /// Manually disposes of native resources.
  ///
  /// This method should be called when the grid is no longer needed to free native memory.
  /// It's only applicable for FFI implementations; calling it on Flutter implementation is safe but has no effect.
  ///
  /// After disposal, the grid should not be used for data access.
  /// Multiple calls to dispose are safe and will be ignored.
  ///
  /// Note: The finalizer provides automatic cleanup, but manual disposal is recommended
  /// for deterministic resource management.
  void dispose() {
    if (!_isDisposed && _isFFIBased) {
      // Free the allocated native memory
      malloc.free(dataPointer);

      // Set pointer to null address to prevent accidental access
      dataPointer = Pointer.fromAddress(0);

      // Detach from finalizer since we've manually cleaned up
      _finalizer.detach(this);

      _isDisposed = true;
    }
  }

  /// Returns the total number of elements in the grid.
  ///
  /// This returns `rows * columns`.
  int get totalElements => rows * columns;

  /// Returns whether this grid has been disposed.
  bool get isDisposed => _isDisposed;
}
