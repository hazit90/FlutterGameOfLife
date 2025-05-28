import 'package:game_of_life/data/input_grid.dart';
import 'package:game_of_life/data/output_grid.dart';
import 'package:game_of_life/data/update_type.dart';

class GolData {
  static const double cellSize = 10.0;

  int rows = 0;
  int columns = 0;
  UpdateType updateType;

  late InputGrid inputGrid;
  late OutputGrid outputGrid;

  GolData(this.rows, this.columns, this.updateType) {
    inputGrid = InputGrid(rows, columns, updateType, initRandom: true);
    outputGrid = OutputGrid(rows, columns, updateType);
  }
}
