import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:game_of_life/data/gol_data.dart';
import 'package:game_of_life/screens/game_screen.dart';

class GameOfLifePainter extends CustomPainter {
  final double cellSize;
  final double scale = 0.05;
  // final Offset canvasOffset;
  GolData golData;

  GameOfLifePainter(
      {required this.golData, this.cellSize = GolData.cellSize} //,
      );

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.square
      ..strokeWidth = cellSize;

    canvas.scale(scale);
    // canvas.translate(canvasOffset.dx,
    //     canvasOffset.dy); // Ensure 'offset' is an Offset object
    paint.color = Colors.black; // set the color for alive cells

    var outputData = golData.outputGrid.data;
    // Use drawRawPoints with the Float32List
    if (!debug) {
      canvas.drawRawPoints(ui.PointMode.points, outputData, paint);
    }
    if (debug) {
      int k = 0;

      // Iterate over each cell in the grid
      for (int y = 0; y < golData.rows * golData.columns; y++) {
        var dx = outputData[k++];
        var dy = outputData[k++];
        canvas.drawRect(
          Rect.fromLTWH(dx, dy, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // You might want to optimize this to reduce unnecessary repaints
  }
}
