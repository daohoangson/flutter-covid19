import 'package:covid19/api/api.dart';
import 'package:covid19/layout.dart';
import 'package:covid19/search.dart';
import 'package:covid19/widget/big_numbers.dart';
import 'package:covid19/widget/map.dart';
import 'package:covid19/widget/table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final child = screenSize.width < screenSize.height
        ? _Portrait()
        : _Landscape(screenSize: screenSize);

    return Scaffold(
      appBar: !kIsWeb
          ? AppBar(
              actions: [CountrySearchButton.icon()],
              title: Text('Covid-19 numbers worldwide'),
            )
          : null,
      body: Consumer<Api>(
        builder: (_, api, child) =>
            api.hasData ? child : _ProgressIndicator(value: api.progress),
        child: child,
      ),
      floatingActionButton: kIsWeb ? CountrySearchButton.fab() : null,
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
    var mapAspectRatio = 1.0;
    var mapWidth = screenSize.height;
    var tableWidth = screenSize.width - mapWidth;
    if (tableWidth < TableWidget.kMinWidth) {
      tableWidth = TableWidget.kMinWidth * 1.1;
      mapWidth = screenSize.width - tableWidth;
      mapAspectRatio = mapWidth / screenSize.height;
    }

    if (mapWidth > Layout.kRequiredWidthForBoth) {
      return _buildWide(mapAspectRatio);
    }

    return _buildNormal(mapAspectRatio);
  }

  Widget _buildNormal(double mapAspectRatio) => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: mapAspectRatio,
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

  Widget _buildWide(double mapAspectRatio) => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: mapAspectRatio,
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
