import 'package:covid19/api/api.dart';
import 'package:covid19/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/screen/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Covid-19',
        home: MultiProvider(
          child: HomeScreen(),
          providers: [
            ChangeNotifierProvider<Api>(create: (_) => WhoApi()),
            ChangeNotifierProvider(create: (_) => AppState()),
          ],
        ),
      );
}
