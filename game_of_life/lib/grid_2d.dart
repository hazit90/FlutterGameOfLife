import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:game_of_life/update_type.dart';

class Grid2D {
  late Pointer<Float> dataPointer;
  late int rows;
  late int columns;
  final random = Random();
  final Finalizer<Pointer<Float>> _finalizer;
  bool _isDisposed = false; // Flag to track manual disposal
  UpdateType updateType;
  late Float32List dataFloatList;
  
  Float32List get data {
    if(updateType == UpdateType.flutter){
      return dataFloatList;
    }
    return toFloat32List();
  }

  operator [](int idx) {
    if (updateType == UpdateType.flutter) {
      return dataFloatList[idx];
    }
    return dataPointer[idx];
  }

  operator []=(int idx, double value) {
    if (updateType == UpdateType.flutter) {
      dataFloatList[idx] = value;
      return;
    }
    dataPointer[idx] = value;
  }

  Grid2D(this.rows, this.columns, this.updateType, {bool initRandom = false})
      : _finalizer = Finalizer<Pointer<Float>>(malloc.free) {
        
    if (updateType == UpdateType.flutter) {
      if (initRandom) {
        dataFloatList = Float32List.fromList(List.generate(
            rows * columns, (_) => random.nextBool() ? 1.0 : 0.0));
      } else {
        dataFloatList = Float32List(rows * columns);
      }
      return;
    }

    if (updateType == UpdateType.cpp) {
      //init native stuff
      dataPointer = malloc.allocate<Float>(sizeOf<Float>() * rows * columns);
      _finalizer.attach(this, dataPointer, detach: this);

      if (initRandom) {
        _initializeGridRandomly();
      }
    }
  }

  void clear() {
    for (int i = 0; i < rows * columns; i++) {
      this[i] = 0.0;
    }
  }

  void _initializeGridRandomly() {
    for (int i = 0; i < rows * columns; i++) {
      this[i] = random.nextBool() ? 1.0 : 0.0;
    }
  }

  // Converts the pointer data to Float32List
  Float32List toFloat32List() {
    return dataPointer.asTypedList(rows * columns);
  }

  // Destructor to free the allocated memory
  void dispose() {
    if (!_isDisposed && updateType != UpdateType.flutter) {
      malloc.free(dataPointer);
      dataPointer = Pointer.fromAddress(0);

      _isDisposed = true;
    }
  }
}

