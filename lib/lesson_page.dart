import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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