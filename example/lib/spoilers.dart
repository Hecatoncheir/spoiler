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
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
            child: Spoilers(
              onUpdateCallback: (details) {
                print(details.isOpened);
                print(details.childHeight);
              },
              header: Text("Spoilers example header"),
              children: <Spoiler>[
                Spoiler(
                  headerWhenSpoilerClosed: Text('First spoiler'),
                  child: Text('First example context'),
                ),
                Spoiler(
                  headerWhenSpoilerClosed: Text('Second spoiler'),
                  child: Text('Second example context'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
