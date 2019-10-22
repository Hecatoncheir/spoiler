import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spoiler/spoiler.dart';

void main() => runApp(Example());

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Spoiler(
            child: Text('Example context'),
          ),
        ),
      ),
    );
  }
}
