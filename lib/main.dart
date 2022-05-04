import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlliCrab',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const MyHomePage(title: 'AlliCrab'),
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
  late Future<int> reviewCount;

  @override
  void initState() {
    super.initState();
    reviewCount = submitApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Material(
          child: GridView.count(
            crossAxisCount: 2,
            children: [
              Material(
                child: getInkSquare('lessons'),
                color: Colors.blue[500],
              ),
              Material(
                child: FutureBuilder<int>(
                  future: reviewCount,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return getInkSquare(snapshot.data!.toString());
                    } else if (snapshot.hasError) {
                      return getInkSquare('${snapshot.error}');
                    }

                    // By default, show a loading spinner.
                    return const CircularProgressIndicator();
                  },
                ),
                color: Colors.orange[500],
              ),
              Material(
                child: getInkSquare('graph'),
                color: Colors.green[500],
              ),
            ],
          ),
          color: Colors.grey,
        ));
  }

  InkWell getInkSquare(String text) {
    return InkWell(
      onTap: () {
        setState(() {});
      },
      child: Center(
        child: Text(text),
      ),
      splashColor: Colors.white,
    );
  }

  Future<int> submitApi() async {
    final x = await http.get(Uri.parse("https://api.wanikani.com/v2/assignments?immediately_available_for_review"),
        headers: {"Authorization" : "Bearer 52b6d8ee-25be-4ee9-9b09-af46db697409"});
    Map<String, dynamic> json = jsonDecode(x.body);
    return json["total_count"];
  }
}
