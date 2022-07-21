import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';
import 'login_page.dart';

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