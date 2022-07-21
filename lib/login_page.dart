
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

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