import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

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

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  State<StatefulWidget> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {

  late List<dynamic> seen;
  late Set<dynamic> reviewSubjectsIds;
  late String id;
  late int chosen;
  late http.Response result1s;

  final answerTextFieldController = TextEditingController();

  bool resulted = false;
  bool shown = false;
  bool next = true;
  bool correct = false;
  DateTime lastTime = DateTime.now();
  Text result = const Text("");
  int ir = 0;
  Map<int, int> meaningsIncorrect = HashMap<int, int>();

  @override
  void dispose() {
    answerTextFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    lastTime.subtract(const Duration(hours: 1));
    final builder = FutureBuilder<List<String>>(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<String>? js = snapshot.data;
          if (js != null) {
            var json1 = jsonDecode(js[0]) as Map<String, dynamic>;
            var json2 = jsonDecode(js[1]) as Map<String, dynamic>;
            reviewSubjectsIds = retrieveSet(json1, ['data'],['id']);
            id = reviewSubjectsIds.elementAt(chosen);
            meaningsIncorrect.putIfAbsent(chosen, () => 0);
            seen = retrieveArray(json2, ['data','meanings'],['meaning']);
            return Column(
                children: [
                  Text(retrieve(json2,['object']),
                      style: const TextStyle(
                          fontSize: 24
                      )),
                  Text(retrieve(json2,['data','characters']),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24
                    )
                  )
                ]
            );
          }
          return const Text('done');
        }
        return const CircularProgressIndicator();
      },
    );

    TextField answerField = TextField(
      controller: answerTextFieldController,
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
          hintText: 'meaning'
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Allicrab'),
        backgroundColor: const Color(0xffe8e8e8),
      ),
      body: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            result,
            builder,
            answerField,
            getButton()
          ],
        ),
      ),
    );
  }

  TextButton getButton() {
    return (!shown?
    TextButton(
        onPressed: () async {
          correct = false;
          for (String s in seen) {
            if (answerTextFieldController.text.toLowerCase() ==
                s.toLowerCase()) {
              correct = true;
              break;
            }
          }
          if (correct) {
            setState(() {
              result = Text('Correct\n${seen.toString()}',
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 24
                  ));
            });
          } else {
            meaningsIncorrect.update(chosen, (value) => value+1);
            setState(() {
              result = Text(seen.toString(),
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 24
                  )
              );
            });
          }
          shown = true;
        },
        child: const Text('Submit',
            textAlign: TextAlign.center)
    )
        :
    TextButton(
      onPressed: () async {
        next = true;
        shown = false;
        answerTextFieldController.clear();
        if (correct) {
          http.post(Uri.parse("https://api.wanikani.com/v2/reviews"),
              headers: {
                "Authorization": "Bearer " + widget.apiKey,
                "Content-Type": "application/json; charset=utf-8"
              },
              body: jsonEncode(<String, Map<String, int>>{
                'review': <String, int>{
                  'assignment_id': int.parse(id),
                  'incorrect_meaning_answers': meaningsIncorrect.putIfAbsent(
                      chosen, () => 0),
                  'incorrect_reading_answers': ir
                }
              })).then(refresh);
          meaningsIncorrect.remove(chosen);
          ir = 0;
        } else {
          refresh(null);
        }
      },
      child: const Text('Continue',
        textAlign: TextAlign.center)
    ));
  }

  FutureOr refresh(dynamic value) {
    setState(() => {
      result = const Text('')
    });
  }

  Future<List<String>> getData() async {
    DateTime now = DateTime.now();
    http.Response result1;
    if (lastTime.hour<now.hour||lastTime.day<now.day||lastTime.month<now.day||lastTime.year<now.year) {
      resulted = true;
      result1 = await http.get(Uri.parse(
        "https://api.wanikani.com/v2/assignments?in_review=true&available_before=${now.toUtc().toIso8601String()}"),
        headers: {"Authorization" : "Bearer "+widget.apiKey});
      result1s = result1;
    } else {
      result1 = result1s;
    }
    lastTime = now;
    dynamic json1 = jsonDecode(result1.body);
    if (next) {
      next = false;
      int len = retrieveSize(json1, ['data']);
      chosen = Random().nextInt(len);
    }
    String id = json1['data'][chosen]['data']['subject_id'].toString();
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? temp = sp.getString(id);
    if (temp==null) {
      final result2 = await http.get(
          Uri.parse('https://api.wanikani.com/v2/subjects/' + id),
          headers: {"Authorization": "Bearer " + widget.apiKey});
      SharedPreferences.getInstance().then((value) =>
          value.setString(id, result2.body));
      temp = result2.body;
    }
    return [result1.body, temp];
  }

  dynamic retrieve(dynamic json, var arr) {
    for (var x in arr) {
      json = json[x];
    }
    return json.toString();
  }

  List<dynamic> retrieveArray(dynamic json, var arr1, var arr2) {
    for (var x in arr1) {
      json = json[x];
    }
    List<dynamic> ans = List.filled(json.length, "", growable: false);
    for (int i = 0; i < json.length; i++) {
      ans[i] = retrieve(json[i], arr2);
    }
    return ans;
  }

  Set<dynamic> retrieveSet(dynamic json, var arr1, var arr2) {
    for (var x in arr1) {
      json = json[x];
    }
    Set<dynamic> ans = HashSet();
    for (int i = 0; i < json.length; i++) {
      ans.add(retrieve(json[i], arr2));
    }
    return ans;
  }

  int retrieveSize(dynamic json, var arr) {
    for (var x in arr) {
      json = json[x];
    }
    return json.length;
  }
}


class LessonPage extends StatefulWidget {
  const LessonPage({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;

  @override
  State<StatefulWidget> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {

  late String id;

  @override
  Widget build(BuildContext context) {
    final builder = FutureBuilder<List<String>>(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<String>? js = snapshot.data;
          if (js != null) {
            var json1 = jsonDecode(js[0]) as Map<String, dynamic>;
            var json2 = jsonDecode(js[1]) as Map<String, dynamic>;
            id = retrieve(json1,['data',0,'id']);
            return Column(
                children: [
                  Text(retrieve(json2,['data','characters']),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24
                      )),
                  Text(retrieve(json2,['object']),
                      style: const TextStyle(
                          fontSize: 24
                      )),
                  Text(retrieve(json2,['data','meanings',0,'meaning']),
                      style: const TextStyle(
                          fontSize: 24
                      )),
                  Text(retrieve(json2,['data','meaning_mnemonic']),
                      style: const TextStyle(
                          fontSize: 24
                      ))
                ]
            );
          }
          return const Text('done');
        }
        return const CircularProgressIndicator();
      },
    );

    TextButton continueButton = TextButton(
        onPressed: () async {
          http.put(Uri.parse('https://api.wanikani.com/v2/assignments/'+id+'/start'), headers: {"Authorization" : "Bearer "+ widget.apiKey}).then(refresh);
        },
        child: const Text('Continue',
            textAlign: TextAlign.center)
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
              continueButton
            ],
          ),
        ),
      ),
    );
  }

  FutureOr refresh(dynamic value) {
    setState(() => {});
  }

  Future<List<String>> getData() async {
    final result1 = await http.get(Uri.parse("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true"),
        headers: {"Authorization" : "Bearer "+widget.apiKey});
    dynamic json1 = jsonDecode(result1.body);
    String id = json1['data'][0]['data']['subject_id'].toString();
    final result2 = await http.get(Uri.parse('https://api.wanikani.com/v2/subjects/'+id),
        headers: {"Authorization" : "Bearer "+widget.apiKey});
    return [result1.body, result2.body];
  }

  String retrieve(dynamic json, var arr) {
    for (var x in arr) {
      json = json[x];
    }
    return json.toString();
  }
}