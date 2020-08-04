import 'package:covid19/data/api.dart';
import 'package:covid19/data/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/screen/home.dart';
import 'package:covid19/screen/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

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
  Widget build(BuildContext _) => Selector<AppState, Tuple2<bool, bool>>(
        builder: (_, values, __) => _build(
          darkTheme: values.item1,
          showPerformanceOverlay: values.item2,
        ),
        selector: (_, app) => Tuple2(app.darkTheme, app.showPerformanceOverlay),
      );

  Widget _build({
    bool darkTheme,
    bool showPerformanceOverlay,
  }) =>
      MaterialApp(
        initialRoute: HomeScreen.kRouteName,
        routes: {
          HomeScreen.kRouteName: (_) => HomeScreen(),
          SettingsScreen.kRouteName: (_) => SettingsScreen(),
        },
        showPerformanceOverlay: showPerformanceOverlay,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: darkTheme == true
            ? ThemeMode.dark
            : darkTheme == false ? ThemeMode.light : ThemeMode.system,
        title: 'Covid-19',
      );
}
