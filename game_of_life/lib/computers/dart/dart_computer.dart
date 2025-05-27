import 'dart:typed_data';
import 'package:game_of_life/data/gol_data.dart';

class DartComputer {
  int rows = 0;
  int columns = 0;
  double cellSize;

  // Pre-allocate reusable buffers to avoid repeated allocations
  late Float32List _tempGrid;
  late Float32List _aliveCellsOutput;

  DartComputer(this.rows, this.columns, this.cellSize) {
    _tempGrid = Float32List(rows * columns);
    _aliveCellsOutput = Float32List(rows * columns * 2);
  }

  void updateDart(GolData golData) {
    var grid = golData.inputGrid.data;
    golData.outputGrid.clear();

    // Reuse pre-allocated buffer
    int k = 0;
    final double halfCellSize = cellSize * 0.5;
    final int maxOutputSize = _aliveCellsOutput.length; // Add bounds check

    // Loop through each cell in the grid
    for (int y = 0; y < rows; y++) {
      final int yOffset = y * columns;
      final double yPos = y * cellSize + halfCellSize;

      for (int x = 0; x < columns; x++) {
        final int index = yOffset + x;

        // Count neighbors inline for better performance
        int neighbors = _countNeighborsInline(x, y, grid);
        bool alive = grid[index] == 1.0;

        // Apply Conway's rules
        bool newState;
        if (alive) {
          newState = neighbors == 2 || neighbors == 3;
        } else {
          newState = neighbors == 3;
        }

        _tempGrid[index] = newState ? 1.0 : 0.0;

        if (newState && k + 1 < maxOutputSize) {
          // Add bounds check
          _aliveCellsOutput[k++] = x * cellSize + halfCellSize;
          _aliveCellsOutput[k++] = yPos;
        }
      }
    }

    // Resize alive cells output to actual size
    golData.outputGrid.dataFloatList = Float32List.view(
      _aliveCellsOutput.buffer,
      0,
      k,
    );

    // Swap buffers instead of copying
    golData.inputGrid.dataFloatList = _tempGrid;
    _tempGrid = Float32List(rows * columns); // Prepare for next iteration
  }

  // Inline neighbor counting for better performance
  int _countNeighborsInline(int x, int y, Float32List grid) {
    int count = 0;
    final int maxX = columns - 1;
    final int maxY = rows - 1;

    // Unroll the neighbor checking loop for better performance
    if (y > 0) {
      final int topRow = (y - 1) * columns;
      if (x > 0 && grid[topRow + x - 1] == 1.0) count++;
      if (grid[topRow + x] == 1.0) count++;
      if (x < maxX && grid[topRow + x + 1] == 1.0) count++;
    }

    final int currentRow = y * columns;
    if (x > 0 && grid[currentRow + x - 1] == 1.0) count++;
    if (x < maxX && grid[currentRow + x + 1] == 1.0) count++;

    if (y < maxY) {
      final int bottomRow = (y + 1) * columns;
      if (x > 0 && grid[bottomRow + x - 1] == 1.0) count++;
      if (grid[bottomRow + x] == 1.0) count++;
      if (x < maxX && grid[bottomRow + x + 1] == 1.0) count++;
    }

    return count;
  }
}
