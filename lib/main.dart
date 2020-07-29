import 'package:covid19/api/api.dart';
import 'package:covid19/api/who.dart';
import 'package:covid19/widget/big_numbers.dart';
import 'package:covid19/widget/map.dart';
import 'package:covid19/widget/table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Covid-19',
        home: MultiProvider(
          child: Scaffold(
            appBar: !kIsWeb
                ? AppBar(title: Text('Covid-19 numbers worldwide'))
                : null,
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
  Widget build(BuildContext _) => Consumer<Api>(
        builder: (_, api, child) =>
            api.hasData ? child : _ProgressIndicator(value: api.progress),
        child: LayoutBuilder(
          builder: (_, bc) =>
              bc.maxWidth < bc.maxHeight ? _LayoutMobile() : _LayoutTablet(),
        ),
      );
}

class _ProgressIndicator extends StatelessWidget {
  final double value;

  const _ProgressIndicator({Key key, this.value}) : super(key: key);

  @override
  Widget build(BuildContext _) => kIsWeb
      ? const Center(child: CircularProgressIndicator())
      : Center(
          child: AspectRatio(
          aspectRatio: kMapPreferredRatio,
          child: MapProgressIndicator(value: value),
        ));
}

class _LayoutMobile extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Stack(
        children: [
          Column(
            children: [
              AspectRatio(aspectRatio: BigNumbersWidget.kPreferredAspectRatio),
              AspectRatio(
                aspectRatio: kMapPreferredRatio,
                child: MapWidget(),
              ),
              Expanded(child: TableWidget()),
            ],
          ),
          Positioned(child: BigNumbersWidget()),
        ],
      );
}

class _LayoutTablet extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: MapWidget(),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                BigNumbersWidget(),
                Expanded(child: TableWidget()),
              ],
            ),
          ),
        ],
      );
}
