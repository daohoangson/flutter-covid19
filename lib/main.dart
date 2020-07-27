import 'package:covid19/api/who.dart';
import 'package:covid19/widget/data_table.dart';
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
              title: Text('Covid-19 numbers worldwide'),
            ),
            body: DataTableWidget(),
          ),
          value: WhoApi.getInstance(),
        ),
      );
}
