import 'package:covid19/api/api.dart';
import 'package:covid19/api/who.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/layout.dart';
import 'package:covid19/search.dart';
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
                ? AppBar(
                    actions: [CountrySearchButton.icon()],
                    title: Text('Covid-19 numbers worldwide'),
                  )
                : null,
            body: _Body(),
            floatingActionButton: kIsWeb ? CountrySearchButton.fab() : null,
          ),
          providers: [
            ChangeNotifierProvider<Api>(create: (_) => WhoApi()),
            ChangeNotifierProvider(create: (_) => AppState()),
          ],
        ),
      );
}

class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final child = screenSize.width < screenSize.height
        ? _Portrait()
        : _Landscape(screenSize: screenSize);

    return Consumer<Api>(
      builder: (_, api, child) =>
          api.hasData ? child : _ProgressIndicator(value: api.progress),
      child: child,
    );
  }
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

class _Portrait extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Stack(
        children: [
          Column(
            children: [
              BigNumbersPlaceholder(),
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

class _Landscape extends StatelessWidget {
  final Size screenSize;

  const _Landscape({Key key, this.screenSize}) : super(key: key);

  @override
  Widget build(BuildContext _) {
    if (screenSize.height > Layout.kRequiredWidthForBoth) {
      return _buildWide();
    }

    return _buildNormal();
  }

  Widget _buildNormal() => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: MapWidget(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, bc) => Column(
                  children: [
                    BigNumbersWidget(bc: bc),
                    Expanded(child: TableWidget()),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildWide() => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Column(
                    children: [
                      BigNumbersPlaceholder(),
                      Expanded(child: MapWidget()),
                    ],
                  ),
                  Positioned(child: BigNumbersWidget()),
                ],
              ),
            ),
            Expanded(child: TableWidget()),
          ],
        ),
      );
}
