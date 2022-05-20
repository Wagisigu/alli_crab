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
      home: LoginPage(),
      //home: const MyHomePage(title: 'AlliCrab'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final apiTextFieldController = TextEditingController();
  String response = '';

  @override
  void dispose() {
    apiTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allicrab'),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(response,
              style: const TextStyle(
                color: Colors.red
              ),
            ),
            TextField(
              controller: apiTextFieldController,
              decoration: const InputDecoration(
                  hintText: 'Enter your api key'
              ),
            ),
            TextButton(
              onPressed: () async {
                final x = await http.get(Uri.parse('https://api.wanikani.com/v2/assignments'),
                    headers: {"Authorization" : "Bearer "+apiTextFieldController.text});
                var json = jsonDecode(x.body);
                if (json['object'].toString() == 'collection') {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(apiKey: apiTextFieldController.text)));
                } else {
                  setState(() => {response = 'Invalid Key'});
                }
              },
              child: const Text('Submit'),
            )
          ],
        )
      ),
    );
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

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
            crossAxisCount: 2,
            children: [
              Material(
                child: getSquare(lessonCount),
                color: Colors.blue[500],
              ),
              Material(
                child: getSquare(reviewCount),
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
      onTap: () => {
        setState(() => {})
      },
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(text),
      ),
      splashColor: Colors.white,
    );
  }

  FutureBuilder<String> getSquare(Future<String> toCome) {
    return FutureBuilder<String>(
    future: toCome,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return getInkSquare(snapshot.data!.toString());
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
