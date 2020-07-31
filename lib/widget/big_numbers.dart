import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/widget/flag.dart';
import 'package:covid19/widget/graph.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BigNumbersWidget extends StatelessWidget {
  static const kPreferredAspectRatio = 4.0;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, app, __) {
          final country = app.highlight != null
              ? api.countries
                  ?.where((country) => country == app.highlight)
                  ?.first
              : null;

          return country != null
              ? _buildCountry(country)
              : _buildWorld(api.worldLatest);
        },
      );

  Widget _buildCountry(ApiCountry country) => Row(
        children: [
          Expanded(
            child: _Card(
              number: country.latest?.deathsTotal,
              number2: country.latest?.deathsNew,
              flag: FlagWidget(country.code),
              graph1: _buildGraph(country, GraphMode.bar, deathsNew),
              graph2: _buildGraph(country, GraphMode.line, deathsTotal),
              title: ' deaths:',
              title2: 'Today: ',
            ),
          ),
          Expanded(
            child: _Card(
              number: country.latest?.casesTotal,
              number2: country.latest?.casesNew,
              graph1: _buildGraph(country, GraphMode.bar, casesNew),
              graph2: _buildGraph(country, GraphMode.line, casesTotal),
              title: 'Total cases:',
              title2: 'New cases: ',
            ),
          ),
        ],
      );

  Widget _buildGraph(ApiCountry country, GraphMode mode, SortOrderPair sop) {
    final record = country.latest;
    final sort = sop.asc;
    final color = kColors[sort.calculateSeriousness(record)];

    return GraphWidget(
      color: color,
      id: "${country.code}-$sort",
      measureFn: sort.measure,
      mode: mode,
      records: country.records,
    );
  }

  Widget _buildWorld(ApiRecord worldLatest) => Row(
        children: [
          Expanded(
            child: _Card(
              number: worldLatest?.deathsTotal,
              number2: worldLatest?.deathsNew,
              title: 'Worldwide deaths:',
              title2: 'Today: ',
            ),
          ),
          Expanded(
            child: _Card(
              number: worldLatest?.casesTotal,
              number2: worldLatest?.casesNew,
              title: 'Total cases:',
              title2: 'New cases: ',
            ),
          ),
        ],
      );
}

class _Card extends StatelessWidget {
  final int number;
  final int number2;
  final Widget flag;
  final Widget graph1;
  final Widget graph2;
  final String title;
  final String title2;

  const _Card({
    Key key,
    @required this.number,
    @required this.number2,
    this.flag,
    this.graph1,
    this.graph2,
    @required this.title,
    @required this.title2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 2,
        child: Card(
          child: Stack(
            children: [
              if (graph1 != null) Positioned.fill(child: graph1),
              if (graph2 != null) Positioned.fill(child: graph2),
              Padding(
                child: Column(
                  children: <Widget>[
                    flag != null
                        ? Row(
                            children: [
                              flag,
                              Expanded(child: _buildTitle()),
                            ],
                          )
                        : _buildTitle(),
                    Expanded(
                      child: number != null
                          ? LayoutBuilder(
                              builder: (_, bc) => Center(
                                child: _JumpingNumberWidget(
                                  number: number,
                                  delta: number2,
                                  style: TextStyle(
                                    fontSize:
                                        min(bc.maxWidth / 7, bc.maxHeight / 2),
                                  ),
                                ),
                                widthFactor: 1,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (number2 != null)
                      Text(
                        '$title2${NumberFormat().format(number2)}',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.caption,
                      )
                  ],
                  crossAxisAlignment: CrossAxisAlignment.start,
                ),
                padding: const EdgeInsets.all(8.0),
              ),
            ],
          ),
        ),
      );

  Widget _buildTitle() => Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}

class _JumpingNumberWidget extends StatefulWidget {
  final int delta;
  final int number;
  final TextStyle style;

  const _JumpingNumberWidget({
    Key key,
    @required this.delta,
    @required this.number,
    @required this.style,
  }) : super(key: key);

  @override
  _JumpingNumberState createState() => _JumpingNumberState();
}

class _JumpingNumberState extends State<_JumpingNumberWidget>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _number;

  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() => setState(() {}));

    _resetAnimation();
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        NumberFormat().format(_number?.value?.toInt() ?? widget.number),
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: widget.style,
      );

  @override
  void didUpdateWidget(_JumpingNumberWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != oldWidget.number) _resetAnimation();
  }

  void _resetAnimation() {
    if (widget.number == null || widget.delta == null) return;

    final number = widget.number.toDouble();
    _number = Tween<double>(
      begin: number - widget.delta,
      end: number,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.ease,
    ));

    _controller
      ..reset()
      ..forward();
  }
}
