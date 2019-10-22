import 'package:flutter/material.dart';

import 'package:spoiler/spoiler.dart';
import 'package:spoiler/spoilers.dart';

void main() => runApp(Example());

class Example extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Spoilers(
            children: <Spoiler>[
              Spoiler(
                header: Text('First spoiler'),
                child: Text('Firsdt example context'),
              ),
              Spoiler(
                header: Text('Second spoiler'),
                child: Text('Second example context'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
