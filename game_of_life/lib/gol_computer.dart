import 'dart:io';

import 'package:game_of_life/computers/cpp_computer.dart';
import 'package:game_of_life/computers/cpp_threads_computer.dart';
import 'package:game_of_life/computers/dart_computer.dart';
import 'package:game_of_life/computers/metal_computer.dart';
import 'package:game_of_life/gol_data.dart';
import 'package:game_of_life/update_type.dart';

class GolComputer {
  int rows = 0;
  int columns = 0;
  double cellSize = GolData.cellSize;
  UpdateType updateType;
  late CppComputer? cppComp;
  late CppThreadsComputer? threadComputer;
  late DartComputer dartComp;
  late MetalComputer? metalComp;
  bool isApple = Platform.isMacOS || Platform.isIOS;

  GolComputer(this.rows, this.columns, this.updateType) {
    if (updateType == UpdateType.flutter) {
      dartComp = DartComputer(rows, columns, cellSize);
    }
    else if (updateType == UpdateType.cpp && isApple) {
      cppComp = CppComputer(rows, columns, cellSize);
    }
    else if (updateType == UpdateType.cppThreads && isApple) {
      threadComputer = CppThreadsComputer(rows, columns, cellSize);
    }
    else if (updateType == UpdateType.metal && isApple) {
      metalComp = MetalComputer(rows, columns, cellSize);
    }
    else{
      updateType = UpdateType.flutter;
      dartComp = DartComputer(rows, columns, cellSize);
    }
  }

  GolData initData() {
    return GolData(rows, columns, updateType);
  }

  void update(GolData golData) {
    if (updateType == UpdateType.flutter) {
      dartComp.updateDart(golData);
    }
    if (updateType == UpdateType.cpp) {
      cppComp?.updateCpp(golData);
    }
    if (updateType == UpdateType.cppThreads) {
      threadComputer?.updateCpp(golData);
    }
    if(updateType == UpdateType.metal){
    metalComp?.updateMetal(golData);
    }
  }

  void dispose() {
    if (updateType == UpdateType.cpp) cppComp?.dispose();
    if (updateType == UpdateType.cppThreads) threadComputer?.dispose();
    if (updateType == UpdateType.metal) metalComp?.dispose();

  }

  
}
