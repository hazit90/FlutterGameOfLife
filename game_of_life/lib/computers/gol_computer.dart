import 'dart:io';

import 'package:game_of_life/computers/cpp/cpp_computer.dart';
import 'package:game_of_life/computers/cpp/cpp_threads_computer.dart';
import 'package:game_of_life/computers/dart/dart_computer.dart';
import 'package:game_of_life/computers/go/golang_computer.dart';
import 'package:game_of_life/computers/go/golang_threads_computer.dart';
import 'package:game_of_life/computers/metal/metal_computer.dart';
import 'package:game_of_life/data/gol_data.dart';
import 'package:game_of_life/data/update_type.dart';

/// A factory and coordinator class for Game of Life computations.
///
/// This class manages different computation backends (Dart, C++, Metal, Go) and
/// provides a unified interface for Game of Life updates. It automatically
/// selects appropriate implementations based on platform capabilities and
/// falls back to Dart implementation when native options are unavailable.
///
/// Example usage:
/// ```dart
/// // Create a computer with C++ backend
/// final computer = GolComputer(100, 100, UpdateType.cpp);
///
/// // Initialize game data
/// final gameData = computer.initData();
///
/// // Run updates
/// computer.update(gameData);
///
/// // Clean up resources
/// computer.dispose();
/// ```
class GolComputer {
  /// Number of rows in the grid.
  final int rows;

  /// Number of columns in the grid.
  final int columns;

  /// Size of each cell for rendering calculations.
  final double cellSize;

  /// The active computation backend type.
  late final UpdateType updateType;

  /// Base interface for all computation backends.
  /// Only one of these will be non-null based on the selected update type.
  late final _ComputerBackend _activeBackend;

  /// Platform detection flags for determining available backends.
  static final bool _isMacOS = Platform.isMacOS;
  static final bool _isApple = Platform.isMacOS || Platform.isIOS;
  static final bool _isAndroid = Platform.isAndroid;
  static final bool _isDesktop =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  /// Creates a new Game of Life computer with the specified configuration.
  ///
  /// Parameters:
  /// - [rows]: Number of rows in the grid. Must be positive.
  /// - [columns]: Number of columns in the grid. Must be positive.
  /// - [updateType]: Desired computation backend type.
  /// - [cellSize]: Size of each cell for rendering. Defaults to [GolData.cellSize].
  ///
  /// If the requested backend is not available on the current platform,
  /// it will automatically fall back to the Dart implementation.
  ///
  /// Throws [ArgumentError] if rows or columns are not positive.
  GolComputer(
    this.rows,
    this.columns,
    UpdateType requestedType, {
    double? cellSize,
  }) : cellSize = cellSize ?? GolData.cellSize {
    // Validate input parameters
    if (rows <= 0 || columns <= 0) {
      throw ArgumentError('Rows and columns must be positive integers');
    }

    // Determine the actual update type based on platform support
    updateType = _selectSupportedUpdateType(requestedType);

    // Initialize the appropriate backend
    _activeBackend = _createBackend(updateType);
  }

  /// Determines if a given update type is supported on the current platform.
  static bool isUpdateTypeSupported(UpdateType type) {
    switch (type) {
      case UpdateType.flutter:
        return true; // Always supported
      case UpdateType.cpp:
      case UpdateType.cppThreads:
        return _isApple || _isAndroid;
      case UpdateType.metal:
        return _isApple;
      case UpdateType.golang:
      case UpdateType.golangThreads:
        return _isMacOS; // Adjust based on your Go library availability
    }
  }

  /// Selects a supported update type, falling back to Flutter if necessary.
  UpdateType _selectSupportedUpdateType(UpdateType requested) {
    if (isUpdateTypeSupported(requested)) {
      return requested;
    }

    // Log the fallback for debugging
    print(
        'Warning: ${requested.name} not supported on ${Platform.operatingSystem}, falling back to Flutter');
    return UpdateType.flutter;
  }

  /// Creates the appropriate backend instance based on update type.
  _ComputerBackend _createBackend(UpdateType type) {
    switch (type) {
      case UpdateType.flutter:
        return _DartBackend(DartComputer(rows, columns, cellSize));
      case UpdateType.cpp:
        return _CppBackend(CppComputer(rows, columns, cellSize));
      case UpdateType.cppThreads:
        return _CppThreadsBackend(CppThreadsComputer(rows, columns, cellSize));
      case UpdateType.metal:
        return _MetalBackend(MetalComputer(rows, columns, cellSize));
      case UpdateType.golang:
        return _GoLangBackend(GoLangComputer(rows, columns, cellSize));
      case UpdateType.golangThreads:
        return _GoLangThreadsBackend(
            GoLangThreadsComputer(rows, columns, cellSize));
    }
  }

  /// Initializes a new [GolData] instance with the current configuration.
  ///
  /// Returns a [GolData] object configured with the grid dimensions and update type.
  GolData initData() {
    return GolData(rows, columns, updateType);
  }

  /// Updates the Game of Life state using the active backend.
  ///
  /// Parameters:
  /// - [golData]: The game data to update.
  ///
  /// The update is performed by the currently active backend implementation.
  void update(GolData golData) {
    _activeBackend.update(golData);
  }

  /// Disposes of resources used by the active backend.
  ///
  /// This method should be called when the computer is no longer needed
  /// to free native resources (if any). It's safe to call multiple times.
  void dispose() {
    _activeBackend.dispose();
  }

  /// Returns a list of all supported update types on the current platform.
  static List<UpdateType> getSupportedUpdateTypes() {
    return UpdateType.values.where(isUpdateTypeSupported).toList();
  }

  /// Returns a human-readable description of the current backend.
  String get backendDescription {
    switch (updateType) {
      case UpdateType.flutter:
        return 'Dart/Flutter (Pure Dart implementation)';
      case UpdateType.cpp:
        return 'C++ (Single-threaded native implementation)';
      case UpdateType.cppThreads:
        return 'C++ Threads (Multi-threaded native implementation)';
      case UpdateType.metal:
        return 'Metal (GPU-accelerated on Apple platforms)';
      case UpdateType.golang:
        return 'Go (Single-threaded Go implementation)';
      case UpdateType.golangThreads:
        return 'Go Threads (Multi-threaded Go implementation)';
    }
  }
}

/// Base interface for computation backends.
///
/// This provides a common interface for all backend implementations,
/// allowing for cleaner polymorphic handling.
abstract class _ComputerBackend {
  void update(GolData golData);
  void dispose();
}

/// Dart backend wrapper.
class _DartBackend implements _ComputerBackend {
  final DartComputer _computer;

  _DartBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateDart(golData);

  @override
  void dispose() {
    // Dart implementation doesn't need explicit disposal
  }
}

/// C++ backend wrapper.
class _CppBackend implements _ComputerBackend {
  final CppComputer _computer;

  _CppBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateCpp(golData);

  @override
  void dispose() => _computer.dispose();
}

/// C++ Threads backend wrapper.
class _CppThreadsBackend implements _ComputerBackend {
  final CppThreadsComputer _computer;

  _CppThreadsBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateCpp(golData);

  @override
  void dispose() => _computer.dispose();
}

/// Metal backend wrapper.
class _MetalBackend implements _ComputerBackend {
  final MetalComputer _computer;

  _MetalBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateMetal(golData);

  @override
  void dispose() => _computer.dispose();
}

/// Go backend wrapper.
class _GoLangBackend implements _ComputerBackend {
  final GoLangComputer _computer;

  _GoLangBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateGo(golData);

  @override
  void dispose() => _computer.dispose();
}

/// Go Threads backend wrapper.
class _GoLangThreadsBackend implements _ComputerBackend {
  final GoLangThreadsComputer _computer;

  _GoLangThreadsBackend(this._computer);

  @override
  void update(GolData golData) => _computer.updateGo(golData);

  @override
  void dispose() => _computer.dispose();
}
