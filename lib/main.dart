import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/loaders/decoders/yaml_decode_strategy.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sudoku/bloc/app_bloc.dart';
import 'package:sudoku/game.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationSupportDirectory(),
  );
  HydratedBlocOverrides.runZoned(
    () => runApp(SudokuApp()),
    storage: storage,
  );
}

class SudokuApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (_) => AppCubit(),
        child: BlocBuilder<AppCubit, AppState>(builder: (context, state) {
          return MaterialApp(
            theme: ThemeData(fontFamily: "Comfortaa"),
            supportedLocales: const [Locale("en"), Locale("de")],
            localizationsDelegates: [
              FlutterI18nDelegate(
                translationLoader: FileTranslationLoader(
                    decodeStrategies: [YamlDecodeStrategy()]),
              ),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate
            ],
            home: Builder(builder: (context) {
              return SafeArea(
                child: WillPopScope(
                  onWillPop: () async {
              if (state.inGame) {
                AppCubit.of(context).quitGame();
                return false;
              }
              return true;
            },
                  child: Scaffold(
                    body: BlocListener<AppCubit, AppState>(
                      listenWhen: (old, now) => now.inGame && now.done,
                      listener: (context, state) {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: Text(FlutterI18n.translate(
                                    context, "dialog.titel")),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        AppCubit.of(context).quitGame();
                                      },
                                      child: Text(FlutterI18n.translate(
                                          context, "dialog.fertig"))),
                                  TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        AppCubit.of(context)
                                            .newGame(state.difficulty);
                                      },
                                      child: Text(FlutterI18n.translate(
                                          context, "dialog.weiter")))
                                ],
                              );
                            },
                            barrierDismissible: false);
                      },
                      child: Column(
                        children: [
                        TopPart(),
                        Sudoko(),
                        Expanded(
                          child: BottomPart(
                            difficulty: state.difficulty,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          );
        }));
  }
}

class TopPart extends StatelessWidget {
  const TopPart({
    Key? key,
  }) : super(key: key);

  Widget menuWidget(BuildContext context) {
    return Text(
      "Sudoku",
      style: TextStyle(fontSize: 54),
    );
  }

  Widget gameWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    FlutterI18n.translate(
                        context, AppCubit.of(context).state.difficultyName),
                    style: TextStyle(fontSize: 15),
                  ))),
          Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () {
                  AppCubit.of(context).quitGame();
                },
                child: Text(FlutterI18n.translate(context, "pause")),
                style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all(Colors.black)),
              ))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: BlocBuilder<AppCubit, AppState>(builder: (context, state) {
        return AnimatedSwitcher(
            child: state.inGame ? gameWidget(context) : menuWidget(context),
            duration: Duration(milliseconds: 300));
      }),
    );
  }
}

class BottomPart extends StatefulWidget {
  final double difficulty;

  const BottomPart({Key? key, required this.difficulty}) : super(key: key);

  @override
  State<BottomPart> createState() => _BottomPartState();
}

class _BottomPartState extends State<BottomPart> {
  late double difficulty = widget.difficulty;

  Color get sliderColor {
    if (difficulty < 0.2) return Colors.green;
    if (difficulty < 0.4) return Colors.green.shade300;
    if (difficulty < 0.6) return Colors.yellow;
    if (difficulty < 0.8) return Colors.orange;
    if (difficulty < 1) return Colors.red;
    return Colors.purple;
  }

  String get difficultyName {
    if (difficulty < 0.2) return "einsteiger";
    if (difficulty < 0.4) return "leicht";
    if (difficulty < 0.6) return "fortgeschritten";
    if (difficulty < 0.8) return "schwer";
    if (difficulty < 1) return "experte";
    return "genie";
  }

  Widget menuWidget(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      return Column(
        //mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (state.grid.any((element) => element != 0) &&
              !state.grid.every((element) => element != 0))
            Padding(
              padding: const EdgeInsets.all(4),
              child: OutlinedButton(
                onPressed: () {
                  AppCubit.of(context).startGame();
                },
                child: Text(
                  FlutterI18n.translate(context, "fortsetzen"),
                  style: TextStyle(fontSize: 32),
                ),
                style: ButtonStyle(
                    side: MaterialStateProperty.all(BorderSide.none),
                    foregroundColor: MaterialStateProperty.all(Colors.black)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: OutlinedButton(
              onPressed: () {
                AppCubit.of(context)
                  ..newGame(difficulty)
                  ..startGame();
              },
              child: Text(
                FlutterI18n.translate(context, "start"),
                style: TextStyle(fontSize: 32),
              ),
              style: ButtonStyle(
                  side: MaterialStateProperty.all(BorderSide.none),
                  foregroundColor: MaterialStateProperty.all(Colors.black)),
            ),
          ),
          Text(
              "${FlutterI18n.translate(context, "schwierigkeitsgrad")}: ${FlutterI18n.translate(context, difficultyName)}",
              style: TextStyle(fontSize: 18)),
          SliderTheme(
            data: SliderThemeData(trackHeight: 16),
            child: Slider(
              value: difficulty,
              onChanged: (v) {
                setState(() {
                  difficulty = v;
                });
              },
              activeColor: sliderColor,
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(builder: (context, state) {
      return AnimatedSwitcher(
          child: Center(child: state.inGame ? InputField() : menuWidget(context)),
          duration: Duration(milliseconds: 300));
    });
  }
}

class Sudoko extends StatelessWidget {
  const Sudoko({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Box([0, 1, 2, 9, 10, 11, 18, 19, 20]),
            Box([3, 4, 5, 12, 13, 14, 21, 22, 23]),
            Box([6, 7, 8, 15, 16, 17, 24, 25, 26])
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Box([27, 28, 29, 36, 37, 38, 45, 46, 47]),
            Box([30, 31, 32, 39, 40, 41, 48, 49, 50]),
            Box([33, 34, 35, 42, 43, 44, 51, 52, 53])
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Box([54, 55, 56, 63, 64, 65, 72, 73, 74]),
            Box([57, 58, 59, 66, 67, 68, 75, 76, 77]),
            Box([60, 61, 62, 69, 70, 71, 78, 79, 80])
          ],
        )
      ],
    );
  }
}

class Box extends StatelessWidget {
  final List<int> indeces;

  const Box(this.indeces, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double size = ((MediaQuery.of(context).size.width - 16) ~/ 9).toDouble();
    double borderWidth = 1.4;

    return Container(
      width: size * 3 + 2 * borderWidth,
      height: size * 3 + 2 * borderWidth,
      decoration: BoxDecoration(border: Border.all(width: borderWidth)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Cell(index: indeces[0]),
              Cell(index: indeces[1]),
              Cell(index: indeces[2]),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Cell(index: indeces[3]),
              Cell(index: indeces[4]),
              Cell(index: indeces[5]),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Cell(index: indeces[6]),
              Cell(index: indeces[7]),
              Cell(index: indeces[8]),
            ],
          )
        ],
      ),
    );
  }
}

class Cell extends StatelessWidget {
  final int index;

  const Cell({Key? key, required this.index}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double size = ((MediaQuery.of(context).size.width - 16) ~/ 9).toDouble();

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        Color? bgColor;
        // cell is in conflict with any other cell
        if (state.conflicts.contains(index)) {
          bgColor = Colors.red.withAlpha(80);
        }
        // cell is selected
        else if (state.selected == index) {
          bgColor = Colors.black.withAlpha(50);
        }
        // cell has same value as selected cell
        else if (state.grid[state.selected] > 0 &&
            state.grid[state.selected] == state.grid[index]) {
          bgColor = Colors.blue.withAlpha(80);
        }

        FontWeight? fontWeight;
        if (state.given.contains(index)) fontWeight = FontWeight.bold;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            AppCubit.of(context).setSelectedIndex(index);
          },
          child: Stack(
            children: [
              Positioned(
                top: 2,
                left: 2,
                child: Text(
                  state.guesses[index].getRange(0, min(state.guesses[index].length, 4)).join(" "),
                  style: TextStyle(fontSize: 9),
                ),
              ),
              if (state.guesses[index].length > 4) Positioned(
                bottom: 2,
                left: 2,
                child: Text(
                  state.guesses[index].getRange(4, state.guesses[index].length).join(" "),
                  style: TextStyle(fontSize: 9),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(width: 0.5),
                  color: bgColor,
                ),
                height: size,
                width: size,
                child: Center(
                  child: Text(
                    "${state.grid[index] == 0 ? "" : state.grid[index]}",
                    style: TextStyle(fontSize: 20, fontWeight: fontWeight),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
