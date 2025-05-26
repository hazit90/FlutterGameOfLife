// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'dart:io';

import 'package:game_of_life/data/gol_data.dart';

typedef _nativeInit = Void Function(Int32 rows, Int32 cols, Double cellSize);
typedef _dartInit = void Function(int rows, int cols, double cellSize);

typedef _nativeUpdate = Pointer<Float> Function();
typedef _dartUpdate = Pointer<Float> Function();

typedef _nativeDestruct = Void Function();
typedef _dartDestruct = void Function();

class CppComputer {
  late DynamicLibrary nativeLib;

  late Function nativeInit;
  late Function nativeUpdate;
  late Function nativeDestruct;

  CppComputer(int rows, int cols, double cellSize) {
    setupNativeLibrary();
    // nativeLib = DynamicLibrary.process();

    nativeInit = nativeLib.lookupFunction<_nativeInit, _dartInit>("initCpp");
    nativeUpdate =
        nativeLib.lookupFunction<_nativeUpdate, _dartUpdate>("updateCpp");
    nativeDestruct =
        nativeLib.lookupFunction<_nativeDestruct, _dartDestruct>("destructCpp");

    //init cpp class
    nativeInit(rows, cols, cellSize);
  }

  void setupNativeLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      nativeLib = DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      nativeLib = DynamicLibrary.open("libgolangApi.so");
    }
  }

  void updateCpp(GolData data) {
    data.outputGrid.dataPointer = nativeUpdate();
  }

  void dispose() {
    nativeDestruct();
  }
}
