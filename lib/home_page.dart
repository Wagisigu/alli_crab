import 'dart:async';
import 'dart:convert';

import 'package:alli_crab/review_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'lesson_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.apiKey, required this.prefs}) : super(key: key);

  final String apiKey;
  final SharedPreferences prefs;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<String> reviewCount;
  late Future<String> lessonCount;

  @override
  void initState() {
    super.initState();
    reviewCount = submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_review",["total_count"], widget.apiKey);
    lessonCount = submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons",["total_count"], widget.apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Allicrab'),
        ),
        body: Material(
          child: GridView.count(
            crossAxisCount: 1,
            children: [
              Material(
                child: getSquare("lessons\n", lessonCount),
                color: const Color(0xFFFF00AA),
              ),
              Material(
                child: getSquare("reviews\n", reviewCount),
                color: const Color(0xFF00AAFF),
              ),
            ],
          ),
          color: Colors.grey,
        ));
  }

  InkWell getInkSquare(String text) {
    FutureOr onGoBack(dynamic value) {
      reviewCount = submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_review",["total_count"], widget.apiKey);
      lessonCount = submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons",["total_count"], widget.apiKey);
      setState(() => {});
    }
    return InkWell(
      onTap: () => {
        setState(() => {}),
        if (text.contains('lessons'))Navigator.push(context, MaterialPageRoute(builder: (context) => LessonPage(apiKey: widget.apiKey))).then(onGoBack)
        else Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewPage(apiKey: widget.apiKey))).then(onGoBack)
      },
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white
          ),
        ),
      ),
      splashColor: Colors.white,
    );
  }

  FutureBuilder<String> getSquare(String name, Future<String> toCome) {
    return FutureBuilder<String>(
      future: toCome,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return getInkSquare(name+snapshot.data!.toString());
        } else if (snapshot.hasError) {
          return getInkSquare('${snapshot.error}');
        }
        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      },
    );
  }

  Future<String> submitApiGet(String url, var path, String apiKey) async {
    final x = await http.get(Uri.parse(url),
        headers: {"Authorization" : "Bearer "+apiKey});
    var json = jsonDecode(x.body);
    for (String s in path) {
      json = json[s];
    }
    return json.toString();
  }
}
