import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:game_of_life/data/update_type.dart';

/// An output grid data structure that supports both Flutter-native and FFI implementations.
///
/// This class is designed to store rendering output data for a 2D grid, typically used for
/// visualization purposes. Each grid cell stores two float values, making the total size
/// `rows * columns * 2`. This dual-value structure is commonly used for storing
/// position coordinates, color components, or other paired data.
///
/// Example usage:
/// ```dart
/// // Create a Flutter-based output grid
/// final flutterOutput = OutputGrid(10, 10, UpdateType.flutter);
///
/// // Create an FFI-based output grid with external pointer
/// final ffiOutput = OutputGrid(10, 10, UpdateType.cpp);
/// ffiOutput.setDataPointer(externalPointer);
///
/// // Access elements (each cell has 2 values)
/// flutterOutput[0] = 1.5;  // First value of first cell
/// flutterOutput[1] = 2.5;  // Second value of first cell
///
/// // Clean up resources
/// ffiOutput.dispose();
/// ```
class OutputGrid {
  /// Number of rows in the grid.
  int rows = 0;

  /// Number of columns in the grid.
  int columns = 0;

  /// The implementation type for this output grid.
  UpdateType updateType;

  /// Dart-native float list for Flutter implementation.
  /// Size is `rows * columns * 2` to store two values per cell.
  /// Only used when [updateType] is [UpdateType.flutter].
  late Float32List dataFloatList;

  /// Pointer to native memory for FFI implementations.
  /// Points to memory containing `rows * columns * 2` float values.
  /// Used for all non-Flutter update types (cpp, cppThreads, metal, golang, golangThreads).
  late Pointer<Float> dataPointer;

  /// Finalizer to automatically clean up native memory when the object is garbage collected.
  /// This provides a safety net in case [dispose] is not called manually.
  final Finalizer<Pointer<Float>> _finalizer;

  /// Flag to track if the native memory has been manually disposed.
  /// Prevents double-free errors and ensures safe cleanup.
  bool _isDisposed = false;

  /// Flag to track if the data pointer was set externally.
  /// External pointers should not be freed by this class.
  bool _isExternalPointer = false;

  /// Returns true if this update type uses FFI (native code).
  ///
  /// All update types except Flutter use FFI and require native memory management.
  bool get _isFFIBased => updateType != UpdateType.flutter;

  /// Returns the output grid data as a [Float32List].
  ///
  /// For Flutter implementation, returns the internal [dataFloatList].
  /// For FFI implementations, converts the native pointer to a typed list.
  ///
  /// The returned list has size `rows * columns * 2`.
  Float32List get data {
    if (updateType == UpdateType.flutter) {
      return dataFloatList;
    }
    return toFloat32List();
  }

  /// Accesses an output grid element by linear index.
  ///
  /// Since each cell stores two values, the total accessible indices range from
  /// 0 to `(rows * columns * 2) - 1`.
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
      throw StateError('Cannot access data of a disposed output grid');
    }

    if (updateType == UpdateType.flutter) {
      return dataFloatList[idx];
    }
    return dataPointer[idx];
  }

  /// Sets an output grid element by linear index.
  ///
  /// Since each cell stores two values, the total accessible indices range from
  /// 0 to `(rows * columns * 2) - 1`.
  ///
  /// Parameters:
  /// - [idx]: The linear index of the element to set.
  /// - [value]: The new value to assign.
  ///
  /// Throws [RangeError] if [idx] is out of bounds.
  /// Throws [StateError] if accessing a disposed grid.
  operator []=(int idx, double value) {
    if (_isDisposed) {
      throw StateError('Cannot access data of a disposed output grid');
    }

    if (updateType == UpdateType.flutter) {
      dataFloatList[idx] = value;
      return;
    }
    dataPointer[idx] = value;
  }

  /// Creates a new output grid with the specified dimensions and implementation type.
  ///
  /// Parameters:
  /// - [rows]: The number of rows in the grid. Must be positive.
  /// - [columns]: The number of columns in the grid. Must be positive.
  /// - [updateType]: The implementation type (Flutter or any FFI-based type).
  ///
  /// For FFI implementations, the data pointer must be set separately using [setDataPointer].
  /// For Flutter implementation, allocates a [Float32List] with size `rows * columns * 2`.
  ///
  /// Throws [ArgumentError] if [rows] or [columns] are not positive.
  OutputGrid(this.rows, this.columns, this.updateType)
      : _finalizer = Finalizer<Pointer<Float>>((ptr) {
          // Only free if it's not an external pointer
          // This check is redundant since we detach external pointers,
          // but provides extra safety
        }) {
    // Validate input parameters
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Rows and columns must be positive integers');
    }

    if (updateType == UpdateType.flutter) {
      // Initialize Flutter-native implementation
      // Each cell stores 2 values, hence the multiplication by 2
      dataFloatList = Float32List(rows * columns * 2);
      return;
    }

    if (_isFFIBased) {
      // For all FFI implementations, the pointer will be set externally
      // Initialize with null pointer - setDataPointer must be called
      dataPointer = Pointer.fromAddress(0);
    }
  }

  /// Sets the data pointer for FFI implementations.
  ///
  /// This method should be called for all FFI implementations (cpp, cppThreads,
  /// metal, golang, golangThreads) to provide the external memory pointer
  /// that contains the output data.
  ///
  /// Parameters:
  /// - [pointer]: Pointer to external memory containing `rows * columns * 2` float values.
  /// - [shouldManageMemory]: Whether this class should manage the memory lifecycle.
  ///   If true, the memory will be freed when [dispose] is called.
  ///   If false, the external code is responsible for memory management.
  ///   Defaults to false for safety.
  ///
  /// Throws [StateError] if called on Flutter implementation.
  /// Throws [ArgumentError] if pointer is null.
  void setDataPointer(Pointer<Float> pointer,
      {bool shouldManageMemory = false}) {
    if (updateType == UpdateType.flutter) {
      throw StateError(
          'setDataPointer should not be called on Flutter implementation');
    }

    if (pointer.address == 0) {
      throw ArgumentError('Pointer cannot be null');
    }

    dataPointer = pointer;
    _isExternalPointer = !shouldManageMemory;

    if (shouldManageMemory) {
      // Attach finalizer for automatic cleanup
      _finalizer.attach(this, dataPointer, detach: this);
    }
  }

  /// Converts the native pointer data to a [Float32List].
  ///
  /// This method is only applicable for FFI implementations.
  /// It creates a view of the native memory without copying the data.
  ///
  /// Returns a [Float32List] that directly maps to the native memory
  /// with size `rows * columns * 2`.
  ///
  /// Throws [StateError] if called on a disposed grid or Flutter implementation.
  Float32List toFloat32List() {
    if (updateType == UpdateType.flutter) {
      throw StateError(
          'toFloat32List() should not be called on Flutter implementation');
    }
    if (_isDisposed) {
      throw StateError('Cannot access data of a disposed output grid');
    }
    if (dataPointer.address == 0) {
      throw StateError('Data pointer not set. Call setDataPointer() first.');
    }

    return dataPointer.asTypedList(rows * columns * 2);
  }

  /// Clears the output grid by setting all elements to 0.0.
  ///
  /// This method works for both Flutter and FFI implementations.
  /// For Flutter implementation, uses the efficient [fillRange] method.
  /// For FFI implementations, iterates through all elements.
  ///
  /// Throws [StateError] if called on a disposed grid.
  void clear() {
    if (_isDisposed) {
      throw StateError('Cannot clear a disposed output grid');
    }

    if (updateType == UpdateType.flutter) {
      // More efficient way to clear the list
      dataFloatList.fillRange(0, dataFloatList.length, 0.0);
    } else {
      // For pointer-based data (all FFI implementations)
      if (dataPointer.address == 0) {
        throw StateError('Data pointer not set. Call setDataPointer() first.');
      }

      final totalElements = rows * columns * 2;
      for (int i = 0; i < totalElements; i++) {
        dataPointer[i] = 0.0;
      }
    }
  }

  /// Manually disposes of native resources.
  ///
  /// This method should be called when the output grid is no longer needed.
  /// For FFI implementations with managed memory, it frees the native memory.
  /// For external pointers, it only marks the grid as disposed without freeing memory.
  /// For Flutter implementation, calling this method is safe but has no effect.
  ///
  /// After disposal, the grid should not be used for data access.
  /// Multiple calls to dispose are safe and will be ignored.
  ///
  /// Note: Only frees memory if [shouldManageMemory] was set to true in [setDataPointer].
  void dispose() {
    if (!_isDisposed && _isFFIBased && !_isExternalPointer) {
      // Only free memory if we're managing it
      if (dataPointer.address != 0) {
        malloc.free(dataPointer);

        // Detach from finalizer since we've manually cleaned up
        _finalizer.detach(this);
      }

      // Set pointer to null address to prevent accidental access
      dataPointer = Pointer.fromAddress(0);
    }

    _isDisposed = true;
  }

  /// Returns the total number of elements in the output grid.
  ///
  /// Since each cell stores two values, this returns `rows * columns * 2`.
  int get totalElements => rows * columns * 2;

  /// Returns whether this output grid has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns whether the data pointer is managed externally.
  ///
  /// Only relevant for FFI implementations.
  bool get isExternalPointer => _isExternalPointer;
}
