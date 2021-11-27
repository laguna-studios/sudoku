import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:sudoku/main.dart';

import 'bloc/app_bloc.dart';

class GameScreen extends StatefulWidget {

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextStyle _style = TextStyle(fontSize: 15);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppCubit, AppState>(
      listenWhen: (old, now) => now.done,
      listener: (context, state) {
        showDialog(context: context, builder: (_) {
          return AlertDialog(
            title: Text(FlutterI18n.translate(context, "dialog.titel")),
            actions: [
              TextButton(onPressed: () {
                Navigator.of(context)..pop()..pop();
              }, child: Text(FlutterI18n.translate(context, "dialog.fertig"))),
              TextButton(onPressed: () {
                Navigator.of(context).pop();
                AppCubit.of(context).newGame(state.difficulty);
              }, child: Text(FlutterI18n.translate(context, "dialog.weiter")))
            ],
          );
        }, barrierDismissible: false);
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Align(alignment: Alignment.centerLeft, child: Text(FlutterI18n.translate(context, state.difficultyName), style: _style,))),
                      Align(alignment: Alignment.centerRight,child: OutlinedButton(onPressed: () {
                        Navigator.pop(context);
                      }, child: Text(FlutterI18n.translate(context, "pause")), style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.black)),))
                    ],
                  ),
                ),
                Center(child: Sudoko()),
                Spacer(),
                InputField(),
                Spacer()
              ],
            ),
          ),
        );
      }
    );
  }
}

class InputField extends StatelessWidget {

  static final ButtonStyle style = ButtonStyle(
    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
    foregroundColor: MaterialStateProperty.all(Colors.black),
    fixedSize: MaterialStateProperty.all(Size(40, 40))
    );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min,children: [
          InputButton(7), InputButton(8), InputButton(9), 
        ],),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [InputButton(4), InputButton(5), InputButton(6), ],),
        Row(mainAxisSize: MainAxisSize.min,children: [InputButton(1), InputButton(2), InputButton(3), ],),
        Row(mainAxisSize: MainAxisSize.min,children: [Padding(
          padding: const EdgeInsets.all(4),
          child: OutlinedButton(style: style, onPressed: () {
            AppCubit.of(context).clearCell();
          }, child: Icon(Icons.clear)),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: OutlinedButton(style: style, onPressed: () {
            AppCubit.of(context).getHint();
          }, child: Icon(Icons.lightbulb)),
        )],),
      ],
    );
  }
}

class InputButton extends StatelessWidget {

  final int value;

  const InputButton(this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {

        Color? bgColor;
        // currently selected value
        if (state.grid[state.selected] ==  value) {
          bgColor = Colors.black.withAlpha(60);
        }
        // currently marked as guess
        else if (state.guesses[state.selected].contains(value)) {
          bgColor = Colors.black.withAlpha(20);
        }

        return Padding(
        padding: const EdgeInsets.all(4),
        child: OutlinedButton(
          style: InputField.style.copyWith(backgroundColor: MaterialStateProperty.all(bgColor)),
          onPressed: (state.given.contains(state.selected)) ? null : () {
          AppCubit.of(context).toggleButton(value);
        }, child: Center(child: Text("$value", style: TextStyle(fontSize: 32)),)),
      );
      },
    );
  }
}
