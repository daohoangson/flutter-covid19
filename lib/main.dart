import 'package:covid19/api/who.dart';
import 'package:covid19/widget/world.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Covid-19',
        home: ChangeNotifierProvider.value(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Covid-19 Worldwide'),
            ),
            body: Covid19World(),
          ),
          value: WhoApi.getInstance(),
        ),
      );
}
