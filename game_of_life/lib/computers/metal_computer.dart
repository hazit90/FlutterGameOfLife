import 'dart:ffi';
import 'dart:io';

import 'package:game_of_life/gol_data.dart';

typedef _nativeInit = Void Function(Int32 rows, Int32 cols, Double cellSize);
typedef _dartInit = void Function(int rows, int cols, double cellSize);

typedef _nativeUpdate = Pointer<Float> Function();
typedef _dartUpdate = Pointer<Float> Function();

typedef _nativeDestruct = Void Function();
typedef _dartDestruct = void Function();

class MetalComputer {
  late DynamicLibrary nativeLib;

  late Function nativeInit;
  late Function nativeUpdate;
  late Function nativeDestruct;

  MetalComputer(int rows, int cols, double cellSize) {
    if (Platform.isMacOS || Platform.isIOS) {
      nativeLib = DynamicLibrary.process();

      nativeInit = nativeLib.lookupFunction<_nativeInit, _dartInit>("initMetal");
      nativeUpdate =
          nativeLib.lookupFunction<_nativeUpdate, _dartUpdate>("updateMetal");
      nativeDestruct = nativeLib
          .lookupFunction<_nativeDestruct, _dartDestruct>("destructMetal");

      //init cpp class
      nativeInit(rows, cols, cellSize);
    }
  }
  void updateMetal(GolData data) {
    data.outputGrid.dataPointer = nativeUpdate();
  }

  void dispose() {
    nativeDestruct();
  }
}
