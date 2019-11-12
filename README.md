# Spoiler [![Actions Status](https://github.com/Hecatoncheir/spoiler/workflows/check/badge.svg)](https://github.com/Hecatoncheir/spoiler/actions)

Spoiler widget for flutter.


## HowTo:
```dart
child: Spoiler(
            openCurve: Curves.elasticOut,
            closeCurve: Curves.elasticIn,
            header: Text("Tools", style: TextStyle(color: Colors.white)),
            child: GameControl()
```

```dart
child: Spoilers(
              onUpdateCallback: (s) {
                print(s.childHeight);
                print(s.isOpened);
              },
              header: Text("Spoilers example header"),
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
            )
```

![Spoiler preview gif](/preview/preview.gif)

## TODO:
 - [x] Custom header. 
 - [ ] Custom open header and custom close header.
 - [x] On open callback with header height and child height arguments.
 - [x] On close callback with header height and child height arguments.
 - [x] Get only header height for spoiler in spoiler widgets.
 - [x] Make Spoilers widget with callback that has all headers height and  all child height.
 - [ ] Add `reverse` parameter for change order of header and child.
 - [ ] Add horizontal spoiler widget.
