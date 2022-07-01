import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late Future<SharedPreferences> prefs = getPrefs();
    return MaterialApp(
      title: 'AlliCrab',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: getWelcome(prefs),
    );
  }

  FutureBuilder<SharedPreferences> getWelcome(Future<SharedPreferences> toCome) {
    return FutureBuilder<SharedPreferences>(
      future: toCome,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          SharedPreferences? prefs = snapshot.data;
          String? apiKey = prefs?.getString('apiKey');
          if (apiKey != null && prefs != null) {
            return MyHomePage(apiKey: apiKey, prefs: prefs);
          } else if (prefs != null) {
            return LoginPage(prefs: prefs);
          }
        }
        // By default, show a loading spinner.
        return const CircularProgressIndicator();
      },
    );
  }
  
  Future<SharedPreferences> getPrefs() async {
    return await SharedPreferences.getInstance();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.prefs}) : super(key: key);

  final SharedPreferences prefs;

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
                  widget.prefs.setString('apiKey', apiTextFieldController.text);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage(apiKey: apiTextFieldController.text, prefs: widget.prefs)));
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
                color: Colors.blue[500],
              ),
              Material(
                child: getSquare("reviews\n", reviewCount),
                color: Colors.orange[500],
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
        textAlign: TextAlign.center
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

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  State<StatefulWidget> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {

  final answerTextFieldController = TextEditingController();
  late String seen;

  @override
  void dispose() {
    answerTextFieldController.dispose();
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
            FutureBuilder<String>(
              future: getImage(getWord()),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  String? s = snapshot.data;
                  if (s != null) {
                    seen = s;
                    return Text(s);
                  }
                  return const Text('done');
                }
                return const CircularProgressIndicator();
              },
            ),
            TextField(
              controller: answerTextFieldController,
            ),
            TextButton(
              onPressed: () async {
                if (answerTextFieldController.text == seen) {

                }
              },
              child: const Text('Submit')
            )
          ],
        ),
      ),
    );
  }
  
  Future<String> getWord() async {
    return submitApiGet("https://api.wanikani.com/v2/assignments", ['data',0,'data','subject_id'], widget.apiKey);
  }

  Future<String> getImage(Future<String> url) async {
    String u = '';
    await url.then((value) => u = value);
    return submitApiGet('https://api.wanikani.com/v2/subjects/'+u, ['data','characters'], widget.apiKey);

  }

  Future<String> submitApiGet(String url, var path, String apiKey) async {
    final x = await http.get(Uri.parse(url),
        headers: {"Authorization" : "Bearer "+apiKey});
    var json = jsonDecode(x.body);
    for (var s in path) {
      json = json[s];
    }
    return json.toString();
  }
}


class LessonPage extends StatefulWidget {
  const LessonPage({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  State<StatefulWidget> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {

  late String seen;
  late String id;

  @override
  Widget build(BuildContext context) {
    final builder = FutureBuilder(
      future: Future.wait([getImage(getWord()),getId()]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasData) {
          String? character = snapshot.data![0];
          String? id = snapshot.data![1];
          if (character != null) {
            this.id = id!;
            seen = character;
            return Text(character,
            textAlign: TextAlign.center);
          }
          return const Text('done');
        }
        return const CircularProgressIndicator();
      },
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allicrab'),
      ),
      body: Material(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              builder,
              TextButton(
                  onPressed: () async {
                    http.put(Uri.parse('https://api.wanikani.com/v2/assignments/'+id+'/start'), headers: {"Authorization" : "Bearer "+ widget.apiKey});
                    setState(() => {build(context)});
                  },
                  child: const Text('Continue',
                  textAlign: TextAlign.center)
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<String> getWord() async {
    return submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true", ['data',0,'data','subject_id'], widget.apiKey);
  }

  Future<String> getId() async {
    return submitApiGet("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true", ['data',0,'id'], widget.apiKey);
  }

  Future<String> getImage(Future<String> url) async {
    String u = '';
    await url.then((value) => u = value);
    return submitApiGet('https://api.wanikani.com/v2/subjects/'+u, ['data','characters'], widget.apiKey);

  }

  Future<String> submitApiGet(String url, var path, String apiKey) async {
    final x = await http.get(Uri.parse(url),
        headers: {"Authorization" : "Bearer "+apiKey});
    var json = jsonDecode(x.body);
    for (var s in path) {
      json = json[s];
    }
    return json.toString();
  }
}