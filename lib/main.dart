import 'package:covid19/api/who.dart';
import 'package:covid19/widget/map.dart';
import 'package:covid19/widget/table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Covid-19',
        home: MultiProvider(
          child: Scaffold(
            appBar: AppBar(
              title: Text('Covid-19 numbers worldwide'),
            ),
            body: _Body(),
          ),
          providers: [
            ChangeNotifierProvider.value(value: WhoApi.getInstance()),
            ChangeNotifierProvider(create: (_) => MapData()),
            ChangeNotifierProvider(create: (_) => TableData()),
          ],
        ),
      );
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext _) => LayoutBuilder(
        builder: (_, bc) => bc.maxWidth < bc.maxHeight
            ? Column(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: MapWidget(),
                  ),
                  Expanded(child: TableWidget()),
                ],
              )
            : Row(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: MapWidget(),
                  ),
                  Expanded(child: TableWidget()),
                ],
              ),
      );
}
