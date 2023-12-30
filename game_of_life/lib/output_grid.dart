import 'dart:ffi';
import 'dart:typed_data';

import 'package:game_of_life/update_type.dart';

class OutputGrid {
  int rows = 0;
  int columns = 0;

  UpdateType updateType;
  late Float32List dataFloatList;

  late Pointer<Float> dataPointer; // Pointer to output

  Float32List get data {
    if (updateType == UpdateType.flutter) {
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

  OutputGrid(this.rows, this.columns, this.updateType){
    if (updateType == UpdateType.flutter) {
      dataFloatList = Float32List(rows * columns *2);
      return;
    }

    if (updateType == UpdateType.cpp) {
      
    }
  }

  // Converts the pointer data to Float32List
  Float32List toFloat32List() {
    return dataPointer.asTypedList(rows * columns * 2);
  }

  // Function to set all values in outputPointer to zero
  void clear() {
    for (int i = 0; i < rows * columns * 2; i++) {
      this[i] = 0.0;
    }
  }

  // Destructor to free the allocated memory
  void dispose() {
   
  }
}
