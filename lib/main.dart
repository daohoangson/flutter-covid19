import 'package:covid19/api/api.dart';
import 'package:covid19/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/screen/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MultiProvider(
      child: MyApp(),
      providers: [
        ChangeNotifierProvider<Api>(create: (_) => WhoApi()),
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
    ));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (_, showPerformanceOverlay, __) => MaterialApp(
          title: 'Covid-19',
          home: HomeScreen(),
          showPerformanceOverlay: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}
