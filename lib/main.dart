import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Color _reviewColor = Colors.blue;
  int _colorRotation = 0;

  InkWell getInkSquare(String text) {
    return InkWell(
      onTap: () {
        setState(() {
          _colorRotation = (_colorRotation + 1) % 5;
          switch (_colorRotation) {
            case 0:
              _reviewColor = Colors.orange;
              return;
            case 1:
              _reviewColor = Colors.pink;
              return;
            case 2:
              _reviewColor = Colors.purple;
              return;
            case 3:
              _reviewColor = Colors.teal;
              return;
            case 4:
              _reviewColor = Colors.brown;
              return;
          }
        });
      },
      child: Center(
        child: Text(text),
      ),
      splashColor: _reviewColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: GridView.count(
          crossAxisCount: 2,
          children: [
            Material(
              child: getInkSquare('lessons'),
              color: Colors.blue[200],
            ),
            Material(
              child: getInkSquare('reviews'),
              color: Colors.orange[200],
            ),
            Material(
              child: getInkSquare('graph'),
              color: Colors.green[200],
            ),
          ],
        ));
  }
}
