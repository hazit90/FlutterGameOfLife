import 'package:game_of_life/data/gol_data.dart';
import 'package:game_of_life/computers/gol_computer.dart';
import 'package:game_of_life/data/update_type.dart';

class GameOfLife {
  final int rows;
  final int columns;
  late GolComputer golComputer;
  late GolData golData;
 

  GameOfLife(
      {required this.rows, required this.columns, required UpdateType updateType}) {
   
      golComputer = GolComputer(rows, columns, updateType);     
      golData = golComputer.initData(); 
    
  }

  void updateGrid() {    
      golComputer.update(golData);
    
  }
  void dispose(){
    golComputer.dispose();
  }
}
