import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:qqwing/qqwing.dart';

// ignore: must_be_immutable
class AppState extends Equatable {
  List<int> solution;
  List<int> grid;
  Set<int> given;
  List<List<int>> guesses;

  int selected;
  double difficulty;

  Set<int> conflicts;

  bool inGame;

  final bool changeFlag;

  String get difficultyName {
    double frac = 1 / 4;

    if (difficulty <= 1 * frac) return "einsteiger";
    if (difficulty <= 2 * frac) return "leicht";
    if (difficulty <= 3 * frac) return "fortgeschritten";
    return "expert";
  }

  int get difficultyInt {
    double frac = 1 / 4;

    if (difficulty <= 1 * frac) return 0;
    if (difficulty <= 2 * frac) return 1;
    if (difficulty <= 3 * frac) return 2;
    return 3;
  }

  bool get done => listEquals(grid, solution);

  AppState(this.solution, this.grid, this.given, this.guesses, this.selected,
      this.difficulty, this.conflicts, this.inGame,
      {this.changeFlag = false});

  @override
  List<Object?> get props => [changeFlag];

  AppState changed() =>
      AppState(solution, grid, given, guesses, selected, difficulty, conflicts, inGame,
          changeFlag: !changeFlag);
}

class AppCubit extends HydratedCubit<AppState> {
  AppCubit()
      : super(AppState(List<int>.filled(81, 1), List<int>.filled(81, 0), {},
            List.generate(81, (index) => []), 0, 0.1, {}, false));

  static AppCubit of(BuildContext context) =>
      BlocProvider.of<AppCubit>(context);

  void _check() {
    state.conflicts.clear();

    // check if the new value is in conflict with any other value
    var indices = state.grid.getIndices(state.selected);
    var box = state.grid.getBox(indices[0]);
    var row = state.grid.getRow(indices[1]);
    var col = state.grid.getColumn(indices[2]);

    var val = state.grid[state.selected];
    if (val == 0) return;

    // check box
    for (int i in box.keys) {
      if (i == state.selected) continue;
      if (box[i] == val) {
        state.conflicts.add(state.selected);
        state.conflicts.add(i);
      }
    }

    // check row
    for (int i in row.keys) {
      if (i == state.selected) continue;
      if (row[i] == val) {
        state.conflicts.add(state.selected);
        state.conflicts.add(i);
      }
    }

    // check column
    for (int i in col.keys) {
      if (i == state.selected) continue;
      if (col[i] == val) {
        state.conflicts.add(state.selected);
        state.conflicts.add(i);
      }
    }
  }

  void toggleButton(int value) {
    // you cant change a given value
    if (state.given.contains(state.selected)) return;

    // if value is a guess remove it
    if (state.guesses[state.selected].contains(value)) {
      state.guesses[state.selected].remove(value);
    }
    // if field does not contain a number then set value
    else if (state.grid[state.selected] == 0) {
      state.grid[state.selected] = value;
    }
    // if field already contains a number different then value then set value
    else if (state.grid[state.selected] != value) {
      state.grid[state.selected] = value;
    }
    // if grid already contains value as value then turn it into a guess
    else if (state.grid[state.selected] == value) {
      state.grid[state.selected] = 0;
      state.guesses[state.selected].add(value);
    }

    // check for errors
    _check();

    emit(state.changed());
  }

  void clearCell() {
    if (state.given.contains(state.selected)) return;

    state.grid[state.selected] = 0;
    state.guesses[state.selected].clear();
    state.conflicts.clear();
    emit(state.changed());
  }

  void getHint() {
    if (state.given.contains(state.selected)) return;

    state.grid[state.selected] = state.solution[state.selected];
    _check();
    emit(state.changed());
  }

  void startGame() {
    state.inGame = true;
    emit(state.changed());
  }

  void quitGame() {
    state.inGame = false;
    emit(state.changed());
  }

  Future<void> newGame(double difficulty) async {
    state.difficulty = difficulty;

    QqwingSudoku sudoku = await Qqwing.generateSudoku(state.difficultyInt);

    List<int> grid = sudoku.grid;
    List<int> solution =
        sudoku.solution;
    Set<int> given = {};

    assert(grid.length == solution.length && grid.length == 81);
    for (int i = 0; i < 81; i++) {
      if (grid[i] != 0) {
        given.add(i);
      }
    }

    state.solution = solution;
    state.selected = 40;
    state.guesses = List.generate(81, (index) => []);
    state.given = given;
    state.grid = grid;
    state.conflicts = {};
    emit(state.changed());
  }

  void setSelectedIndex(int index) {
    if (state.conflicts.isNotEmpty) return;
    state.selected = index;
    emit(state.changed());
  }

  @override
  AppState? fromJson(Map<String, dynamic> json) {

    try {
      return AppState(
        json["solution"],
        json["grid"],
        Set.from(json["given"]),
        List<dynamic>.from(json["guesses"])
            .map((e) => List<int>.from(e))
            .toList(),
        json["selected"],
        json["difficulty"],
        Set.from(json["conflicts"]),
        false
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Map<String, dynamic>? toJson(AppState state) {
    return {
      "solution": state.solution,
      "grid": state.grid,
      "given": state.given.toList(),
      "guesses": state.guesses,
      "selected": state.selected,
      "difficulty": state.difficulty,
      "conflicts": state.conflicts.toList()
    };
  }
}

extension SudokuData on List<int> {
  void assertSudoku() {
    assert(length == 81);
  }

  /// returns array containing box index, row index and column index
  List<int> getIndices(int index) {
    int row = index ~/ 9;
    int col = index % 9;
    int box = (row ~/ 3) * 3 + (col ~/ 3);

    return [box, row, col];
  }

  Map<int, int> getRow(int index) {
    assertSudoku();
    if (index < 0 || 8 < index) return {};

    Map<int, int> result = {};

    for (int i = index * 9; i < index * 9 + 9; i++) {
      result[i] = this[i];
    }

    assert(result.keys.length == 9);
    return result;
  }

  Map<int, int> getColumn(int index) {
    assertSudoku();
    if (index < 0 || 8 < index) return {};

    Map<int, int> result = {};

    for (int i = 0; i < 9; i++) {
      result[index + (i * 9)] = this[index + (i * 9)];
    }

    assert(result.keys.length == 9);
    return result;
  }

  /// get list of values in box with index
  /// order of boxes:
  /// 0 1 2
  /// 3 4 5
  /// 6 7 8
  Map<int, int> getBox(int index) {
    assertSudoku();
    if (index < 0 || 8 < index) return {};

    int base = (index ~/ 3) * 27 + (index % 3) * 3;

    return {
      base: this[base],
      base + 1: this[base + 1],
      base + 2: this[base + 2],
      base + 9: this[base + 9],
      base + 10: this[base + 10],
      base + 11: this[base + 11],
      base + 18: this[base + 18],
      base + 19: this[base + 19],
      base + 20: this[base + 20],
    };
  }
}
