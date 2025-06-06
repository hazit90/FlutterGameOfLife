import 'package:flutter/material.dart';
import 'package:game_of_life/game_of_life.dart';
import 'dart:async';
import 'package:game_of_life/data/update_type.dart';
import 'package:circular_buffer/circular_buffer.dart';

import 'gameoflife_painter.dart';

bool debug = false;

class GameScreen extends StatefulWidget {
  final int rows;
  final int columns;
  final UpdateType updateType;

  const GameScreen(
      {super.key,
      required this.rows,
      required this.columns,
      required this.updateType});

  @override
  // ignore: library_private_types_in_public_api
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameOfLife gameOfLife;
  Timer? timer;
  Timer? fpsTimer;
  DateTime? lastFrameTime;
  double fps = 0.0;
  double scale = 1.0;
  Offset offset = Offset.zero;
  bool _isUpdating = false;
  Offset dragStartOffset = Offset.zero; // To store the initial touch position
  bool isDragging = false;

  double initialScale = 1.0; // To store the scale at the beginning of a gesture
  Offset initialFocalPoint =
      Offset.zero; // To store the initial focal point of the gesture
  final TransformationController _transformationController =
      TransformationController();
  final fpsBuffer = CircularBuffer<double>(100);
  double averageFPS = 0;

  @override
  void initState() {
    // _transformMatrix = Matrix4.identity();
    gameOfLife = GameOfLife(
        rows: widget.rows,
        columns: widget.columns,
        updateType: widget.updateType);
    timer = Timer.periodic(const Duration(milliseconds: 1), (timer) {
      if (!_isUpdating) {
        _isUpdating = true;
        Future updated = update();
        updated.then((value) => setState(() {
              _isUpdating = false;
            }));
      }
    });
    fpsTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (fpsBuffer.isNotEmpty) {
        setState(() {
          averageFPS = fpsBuffer.reduce((a, b) => a + b) / fpsBuffer.length;
        });
      }
    });
    super.initState();
  }

  Future update() async {
    final now = DateTime.now();
    if (lastFrameTime != null) {
      final frameDuration = now.difference(lastFrameTime!);
      if (frameDuration.inMilliseconds > 0) {
        fps = 1000000.0 / frameDuration.inMicroseconds;
        fpsBuffer.add(fps);
      }
    }
    lastFrameTime = now;

    gameOfLife.updateGrid();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Game of Life: ${gameOfLife.golComputer.updateType.name}: ${averageFPS.toStringAsFixed(2)} FPS'),
      ),
      body: InteractiveViewer(
        onInteractionUpdate: (ScaleUpdateDetails details) {
          // Adjust this value to control the zoom sensitivity
          const double zoomSensitivity = 0.02;
          final double currentScale =
              _transformationController.value.getMaxScaleOnAxis();
          final double newScale =
              currentScale * (1 + (details.scale - 1) * zoomSensitivity);
          _transformationController.value =
              Matrix4.diagonal3Values(newScale, newScale, 1.0);
        },
        boundaryMargin: const EdgeInsets.all(1800), // Adjust as needed
        minScale: 0.5, // Minimum zoom scale
        maxScale: 50.0, // Maximum zoom scale
        child: CustomPaint(
          painter: GameOfLifePainter(
            golData: gameOfLife.golData,
          ),
          child:
              const SizedBox(width: double.infinity, height: double.infinity),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    fpsTimer?.cancel();
    super.dispose();
    gameOfLife.dispose();
  }
}
