import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

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
    final builder = FutureBuilder<List<List<String>>>(
      future: getData(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<List<String>>? js = snapshot.data;
          if (js != null) {
            var json1 = jsonDecode(js[0][0]) as Map<String, dynamic>;
            List<dynamic> l = List.filled(js[1].length, "", growable: false);
            for (int i = 0; i < js[1].length; i++) {
              l[i] = jsonDecode(js[1][i]);
            }
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

  Future<List<List<String>>> getData() async {
    final result1 = await http.get(Uri.parse("https://api.wanikani.com/v2/assignments?immediately_available_for_lessons=true"),
        headers: {"Authorization" : "Bearer "+widget.apiKey});
    dynamic json1 = jsonDecode(result1.body);
    List<String> ids = retrieveArray(json1, ['data'], ['data','subject_id'], 5);
    List<String> bods = List.filled(ids.length, "", growable: false);
    for (int i = 0; i < ids.length; i++) {
      final temp = await http.get(Uri.parse('https://api.wanikani.com/v2/subjects/'+ids[i]),
          headers: {"Authorization" : "Bearer "+widget.apiKey});
      bods[i] = temp.body;
    }
    return [[result1.body], bods];
  }

  String retrieve(dynamic json, var arr) {
    for (var x in arr) {
      json = json[x];
    }
    return json.toString();
  }

  List<String> retrieveArray(dynamic json, var arr1, var arr2, int limit) {
    for (var x in arr1) {
      json = json[x];
    }
    List<String> ans = List.filled(min(json.length,limit), "", growable: false);
    for (int i = 0; i < min(json.length,limit); i++) {
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