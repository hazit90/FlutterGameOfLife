import 'dart:io';

import 'package:game_of_life/computers/cpp/cpp_computer.dart';
import 'package:game_of_life/computers/cpp/cpp_threads_computer.dart';
import 'package:game_of_life/computers/dart/dart_computer.dart';
import 'package:game_of_life/computers/go/golang_computer.dart';
import 'package:game_of_life/computers/go/golang_threads_computer.dart';
import 'package:game_of_life/computers/metal/metal_computer.dart';
import 'package:game_of_life/data/gol_data.dart';
import 'package:game_of_life/data/update_type.dart';

class GolComputer {
  int rows = 0;
  int columns = 0;
  double cellSize = GolData.cellSize;
  UpdateType updateType;
  late CppComputer? cppComp;
  late CppThreadsComputer? threadComputer;
  late DartComputer dartComp;
  late GoLangComputer? golangComp;
  late GoLangThreadsComputer? golangThreadsComp;
  late MetalComputer? metalComp;
  bool isApple = Platform.isMacOS || Platform.isIOS;
  bool isAndroid = Platform.isAndroid;

  GolComputer(this.rows, this.columns, this.updateType) {
    if (updateType == UpdateType.flutter) {
      dartComp = DartComputer(rows, columns, cellSize);
    } else if (updateType == UpdateType.cpp && (isApple || isAndroid)) {
      cppComp = CppComputer(rows, columns, cellSize);
    } else if (updateType == UpdateType.cppThreads && (isApple || isAndroid)) {
      threadComputer = CppThreadsComputer(rows, columns, cellSize);
    } else if (updateType == UpdateType.metal && isApple) {
      metalComp = MetalComputer(rows, columns, cellSize);
    } else if (updateType == UpdateType.golang && (isApple)) {
      golangComp = GoLangComputer(rows, columns, cellSize);
    } else if (updateType == UpdateType.golangThreads && (isApple)) {
      golangThreadsComp = GoLangThreadsComputer(rows, columns, cellSize);
    } else {
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
    if (updateType == UpdateType.metal) {
      metalComp?.updateMetal(golData);
    }
    if (updateType == UpdateType.golang) {
      golangComp?.updateGo(golData);
    }
    if (updateType == UpdateType.golangThreads) {
      golangThreadsComp?.updateGo(golData);
    }
  }

  void dispose() {
    if (updateType == UpdateType.cpp) cppComp?.dispose();
    if (updateType == UpdateType.cppThreads) threadComputer?.dispose();
    if (updateType == UpdateType.metal) metalComp?.dispose();
    if (updateType == UpdateType.golang) golangComp?.dispose();
    if (updateType == UpdateType.golangThreads) golangThreadsComp?.dispose();
  }
}
