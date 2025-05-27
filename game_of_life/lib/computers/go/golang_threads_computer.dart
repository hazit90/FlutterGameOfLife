import 'dart:ffi';
import 'dart:io';

import 'package:game_of_life/data/gol_data.dart';

typedef _nativeInitGo = Void Function(Int32 rows, Int32 cols, Double cellSize);
typedef _dartInitGo = void Function(int rows, int cols, double cellSize);

typedef _nativeUpdateGo = Pointer<Float> Function();
typedef _dartUpdateGo = Pointer<Float> Function();

typedef _nativeDestructGo = Void Function();
typedef _dartDestructGo = void Function();

class GoLangThreadsComputer {
  late DynamicLibrary nativeLib;

  late Function nativeInitGo;
  late Function nativeUpdateGo;
  late Function nativeDestructGo;

  GoLangThreadsComputer(int rows, int cols, double cellSize) {
    setupNativeLibrary();

    nativeInitGo =
        nativeLib.lookupFunction<_nativeInitGo, _dartInitGo>("initGo");
    nativeUpdateGo =
        nativeLib.lookupFunction<_nativeUpdateGo, _dartUpdateGo>("updateGo");
    nativeDestructGo = nativeLib
        .lookupFunction<_nativeDestructGo, _dartDestructGo>("destructGo");

    nativeInitGo(rows, cols, cellSize);
  }

  void setupNativeLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      nativeLib = DynamicLibrary.open("libgoThreadsApi.dylib");
    } else if (Platform.isAndroid) {
      nativeLib = DynamicLibrary.open("libgoThreadsApi.so");
    }
  }

  void updateGo(GolData data) {
    data.outputGrid.dataPointer = nativeUpdateGo();
  }

  void dispose() {
    nativeDestructGo();
  }
}
