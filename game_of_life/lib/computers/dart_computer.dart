
import 'dart:typed_data';
import 'package:game_of_life/gol_data.dart';


class DartComputer{
  int rows = 0;
  int columns = 0;
  double cellSize;

  DartComputer(this.rows, this.columns, this.cellSize);

  void updateDart(GolData golData) {
    // Access the current grid data
    var grid = golData.inputGrid.data;
    Float32List aliveCellsOutput = Float32List(rows * columns *2);

    golData.outputGrid.clear();    
    
    // Grid2D newGrid = Grid2D(rows, columns, UpdateType.flutter); 
    Float32List newGrid = Float32List(rows * columns);
  
    // Index for tracking the alive cells in aliveCellsOutput
    int k = 0;

    // Loop through each cell in the grid
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < columns; x++) {
        // Count the number of live neighbors for the current cell
        int neighbors = countNeighbors(x, y, grid);

        // Check if the current cell is alive
        bool alive = grid[y * columns + x] == 1.0;

        if (alive && (neighbors < 2 || neighbors > 3)) { //rule 1 and 3.
          newGrid[y * columns + x] = 0.0;
        } else if (!alive && neighbors == 3) { //rule 4
          newGrid[y * columns + x] = 1.0;
        } else {
          // If the state doesn't change, copy the current state
          newGrid[y * columns + x] = grid[y * columns + x];
        }
        if (newGrid[y * columns + x] == 1.0) {
          aliveCellsOutput[k++] = x * cellSize + cellSize / 2;
          aliveCellsOutput[k++] = y * cellSize + cellSize / 2;
        }
      }
    }

    golData.outputGrid.dataFloatList = aliveCellsOutput;
    // Update the grid data with the new generation
    // var tempGrid = golData.inputGrid;
    golData.inputGrid.dataFloatList = newGrid;
    // tempGrid.dispose();

  }

  int countNeighbors(int x, int y, Float32List grid) {
    int count = 0;
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int nx = x + i, ny = y + j;
        if (nx >= 0 && nx < rows && ny >= 0 && ny < columns) {
          count += grid[ny * rows + nx] == 1.0 ? 1 : 0;
        }
      }
    }
    return count;
  }
}