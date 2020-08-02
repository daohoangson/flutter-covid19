import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/layout.dart';
import 'package:covid19/widget/flag.dart';
import 'package:covid19/widget/graph.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BigNumbersWidget extends StatelessWidget {
  final BoxConstraints bc;

  const BigNumbersWidget({this.bc, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      bc != null ? _build(context, bc) : LayoutBuilder(builder: _build);

  static Widget _build(BuildContext _, BoxConstraints bc) =>
      Selector<AppState, ApiCountry>(
        builder: (context, highlight, _) {
          final api = Provider.of<Api>(context);
          final country = highlight != null
              ? api.countries?.where((country) => country == highlight)?.first
              : null;
          final layout = BigNumbersPlaceholder._layout(bc);

          return country != null
              ? _buildCountry(country, layout)
              : _buildWorld(api.worldLatest, layout);
        },
        selector: (_, app) => app.highlight,
      );

  static Widget _buildCountry(ApiCountry country, Layout layout) => Row(
        children: [
          Expanded(
            child: _Card(
              number: country.latest?.deathsTotal,
              number2: layout.showBoth ? null : country.latest?.deathsNew,
              flag: FlagWidget(country.code),
              graph1: layout.showBoth
                  ? null
                  : _buildGraph(country, GraphMode.bar, deathsNew),
              graph2: _buildGraph(country, GraphMode.line, deathsTotal),
              title: ' deaths:',
              title2: 'Today: ',
            ),
          ),
          if (layout.showBoth)
            Expanded(
              child: _Card(
                number: country.latest?.deathsNew,
                graph1: _buildGraph(country, GraphMode.bar, deathsNew),
                title: 'Today deaths:',
              ),
            ),
          Expanded(
            child: _Card(
              number: country.latest?.casesTotal,
              number2: layout.showBoth ? null : country.latest?.casesNew,
              graph1: layout.showBoth
                  ? null
                  : _buildGraph(country, GraphMode.bar, casesNew),
              graph2: _buildGraph(country, GraphMode.line, casesTotal),
              title: 'Total cases:',
              title2: 'New cases: ',
            ),
          ),
          if (layout.showBoth)
            Expanded(
              child: _Card(
                number: country.latest?.casesNew,
                graph1: _buildGraph(country, GraphMode.bar, casesNew),
                title: 'New cases: ',
              ),
            ),
        ],
      );

  static Widget _buildGraph(ApiCountry c, GraphMode m, SortOrderPair s) =>
      GraphWidget(country: c, mode: m, sort: s.asc);

  static Widget _buildWorld(ApiRecord worldLatest, Layout layout) => Row(
        children: [
          Expanded(
            child: _Card(
              number: worldLatest?.deathsTotal,
              number2: layout.showBoth ? null : worldLatest?.deathsNew,
              title: 'Worldwide deaths:',
              title2: 'Today: ',
            ),
          ),
          if (layout.showBoth)
            Expanded(
              child: _Card(
                number: worldLatest?.deathsNew,
                title: 'Today deaths:',
              ),
            ),
          Expanded(
            child: _Card(
              number: worldLatest?.casesTotal,
              number2: layout.showBoth ? null : worldLatest?.casesNew,
              title: 'Total cases:',
              title2: 'New: ',
            ),
          ),
          if (layout.showBoth)
            Expanded(
              child: _Card(
                number: worldLatest?.casesNew,
                title: 'New cases:',
              ),
            ),
        ],
      );
}

class BigNumbersPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext _) => LayoutBuilder(
        builder: (_, bc) =>
            AspectRatio(aspectRatio: _layout(bc).showBoth ? 8 : 4),
      );

  static Layout _layout(BoxConstraints bc) =>
      bc.maxWidth > Layout.kRequiredWidthForBoth || bc.maxHeight < bc.maxWidth
          ? layoutBoth
          : layoutTotal;
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
    this.number2,
    this.flag,
    this.graph1,
    this.graph2,
    @required this.title,
    this.title2,
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
                    Expanded(
                      child: _AutoFontSizeWidget(
                        child: flag != null
                            ? Row(
                                children: [
                                  flag,
                                  Expanded(child: _buildTitle()),
                                ],
                              )
                            : _buildTitle(),
                        widthFactor: 12,
                      ),
                    ),
                    Expanded(
                      child: number != null
                          ? _AutoFontSizeWidget(
                              child: Center(
                                child: _JumpingNumberWidget(
                                  number: number,
                                  delta: number2,
                                ),
                                widthFactor: 1,
                              ),
                              widthFactor: 6,
                            )
                          : const SizedBox.shrink(),
                      flex: 2,
                    ),
                    if (number2 != null && title2 != null)
                      Expanded(
                        child: _AutoFontSizeWidget(
                          child: Text(
                            '$title2${NumberFormat().format(number2)}',
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                          ),
                          widthFactor: 12,
                        ),
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

class _AutoFontSizeWidget extends StatelessWidget {
  final Widget child;
  final double widthFactor;

  const _AutoFontSizeWidget({
    @required this.child,
    Key key,
    @required this.widthFactor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, bc) => DefaultTextStyle(
            child: child,
            style: DefaultTextStyle.of(context).style.copyWith(
                  fontSize: bc.maxWidth / widthFactor,
                )),
      );
}

class _JumpingNumberWidget extends StatefulWidget {
  final int delta;
  final int number;

  const _JumpingNumberWidget({
    Key key,
    this.delta,
    @required this.number,
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
