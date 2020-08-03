import 'package:covid19/data/api.dart';
import 'package:covid19/data/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/screen/home.dart';
import 'package:covid19/screen/settings.dart';
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
          initialRoute: HomeScreen.kRouteName,
          routes: {
            HomeScreen.kRouteName: (_) => HomeScreen(),
            SettingsScreen.kRouteName: (_) => SettingsScreen(),
          },
          title: 'Covid-19',
          showPerformanceOverlay: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}
