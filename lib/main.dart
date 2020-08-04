import 'package:covid19/data/api.dart';
import 'package:covid19/data/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/screen/home.dart';
import 'package:covid19/screen/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = AppState();
  await app.loadPrefs();

  runApp(MultiProvider(
    child: MyApp(),
    providers: [
      ChangeNotifierProvider<Api>(create: (_) => WhoApi()),
      ChangeNotifierProvider.value(value: app),
    ],
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (_, showPerformanceOverlay, __) => MaterialApp(
          initialRoute: HomeScreen.kRouteName,
          routes: {
            HomeScreen.kRouteName: (_) => HomeScreen(),
            SettingsScreen.kRouteName: (_) => SettingsScreen(),
          },
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          title: 'Covid-19',
          showPerformanceOverlay: showPerformanceOverlay,
        ),
        selector: (_, app) => app.showPerformanceOverlay,
      );
}
