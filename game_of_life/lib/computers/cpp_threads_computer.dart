import 'dart:ffi';
import 'dart:io';

import 'package:game_of_life/data/gol_data.dart';

typedef _nativeInit = Void Function(Int32 rows, Int32 cols, Double cellSize);
typedef _dartInit = void Function(int rows, int cols, double cellSize);

typedef _nativeUpdate = Pointer<Float> Function();
typedef _dartUpdate = Pointer<Float> Function();

typedef _nativeDestruct = Void Function();
typedef _dartDestruct = void Function();

class CppThreadsComputer {
  late DynamicLibrary nativeLib;
  late Function nativeInit;
  late Function nativeUpdate;
  late Function nativeDestruct;

  CppThreadsComputer(int rows, int cols, double cellSize) {
    setupNativeLibrary();
    nativeInit =
        nativeLib.lookupFunction<_nativeInit, _dartInit>("initCppThreads");
    nativeUpdate = nativeLib
        .lookupFunction<_nativeUpdate, _dartUpdate>("updateCppThreads");
    nativeDestruct = nativeLib
        .lookupFunction<_nativeDestruct, _dartDestruct>("destructCppThreads");

    //init cpp class
    nativeInit(rows, cols, cellSize);
  }

  void setupNativeLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      nativeLib = DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      nativeLib = DynamicLibrary.open("libcppThreadsApi.so");
    }
  }

  void updateCpp(GolData data) {
    data.outputGrid.dataPointer = nativeUpdate();
  }

  void dispose() {
    nativeDestruct();
  }
}
