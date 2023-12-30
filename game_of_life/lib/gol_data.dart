import 'package:game_of_life/grid_2d.dart';
import 'package:game_of_life/output_grid.dart';
import 'package:game_of_life/update_type.dart';

class GolData {
  static const double cellSize = 10.0;

  int rows = 0;
  int columns = 0;
  UpdateType updateType;

  late Grid2D inputGrid;
  late OutputGrid outputGrid;


  GolData(this.rows, this.columns, this.updateType) {

    inputGrid = Grid2D(rows, columns, updateType, initRandom: true);
    outputGrid = OutputGrid(rows, columns, updateType);
    
  }

}
