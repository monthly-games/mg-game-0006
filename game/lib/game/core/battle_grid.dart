import 'dart:math';

class GridCell {
  final int row;
  final int col;
  String? occupantId; // ID of the UnitEntity occupying this cell

  GridCell(this.row, this.col);

  bool get isEmpty => occupantId == null;
}

class BattleGrid {
  final int rows;
  final int cols;
  final double cellWidth;
  final double cellHeight;

  late List<List<GridCell>> _grid;

  BattleGrid({
    this.rows = 8,
    this.cols = 6,
    this.cellWidth = 64.0,
    this.cellHeight = 64.0,
  }) {
    _grid = List.generate(
      rows,
      (r) => List.generate(cols, (c) => GridCell(r, c)),
    );
  }

  GridCell? getCell(int r, int c) {
    if (isValid(r, c)) {
      return _grid[r][c];
    }
    return null;
  }

  bool isValid(int r, int c) {
    return r >= 0 && r < rows && c >= 0 && c < cols;
  }

  // Convert Grid Cell to World Position (Center of cell)
  Point<double> getPosition(int r, int c) {
    double x = c * cellWidth + (cellWidth / 2);
    double y = r * cellHeight + (cellHeight / 2);
    return Point(x, y);
  }

  // Convert World Position to Grid Cell (Approx)
  GridCell? getCellFromPosition(double x, double y) {
    int c = (x / cellWidth).floor();
    int r = (y / cellHeight).floor();
    return getCell(r, c);
  }

  void placeUnit(int r, int c, String unitId) {
    if (isValid(r, c)) {
      _grid[r][c].occupantId = unitId;
    }
  }

  void clearCell(int r, int c) {
    if (isValid(r, c)) {
      _grid[r][c].occupantId = null;
    }
  }

  // Find nearest empty cell (Simple BFS placeholder)
  GridCell? findNearestEmpty(int startR, int startC) {
    // ... Implementation for Phase 2 pathfinding ...
    return null;
  }
}
