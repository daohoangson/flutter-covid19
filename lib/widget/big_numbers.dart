import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/widget/flag.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BigNumbersWidget extends StatelessWidget {
  static const kPreferredAspectRatio = 4.0;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, app, __) => app.highlight != null
            ? _buildCountry(api.countries
                ?.where((country) => country == app.highlight)
                ?.first)
            : _buildWorld(api.worldLatest),
      );

  Widget _buildCountry(ApiCountry country) => Row(
        children: [
          Expanded(
            child: _Card(
              countryCode: country?.code,
              number: country?.latest?.deathsTotal,
              number2: country?.latest?.deathsNew,
              title: ' deaths:',
              title2: 'Today: ',
            ),
          ),
          Expanded(
            child: _Card(
              number: country?.latest?.casesTotal,
              number2: country?.latest?.casesNew,
              title: 'Total cases:',
              title2: 'New cases: ',
            ),
          ),
        ],
      );

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
  final String countryCode;
  final int number;
  final int number2;
  final String title;
  final String title2;

  const _Card({
    this.countryCode,
    Key key,
    @required this.number,
    @required this.number2,
    @required this.title,
    @required this.title2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 2,
        child: Card(
          child: Padding(
            child: Column(
              children: <Widget>[
                _Title(
                  countryCode: countryCode,
                  title: title,
                ),
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
        ),
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

class _Title extends StatelessWidget {
  final String countryCode;
  final String title;

  const _Title({
    this.countryCode,
    Key key,
    @required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => countryCode != null
      ? Row(
          children: <Widget>[
            FlagWidget(countryCode),
            Expanded(child: _buildText()),
          ],
        )
      : _buildText();

  Widget _buildText() => Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
}
