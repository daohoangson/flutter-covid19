import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BigNumbersWidget extends StatelessWidget {
  static const kPreferredAspectRatio = 4.0;

  @override
  Widget build(BuildContext _) => Consumer<Api>(
        builder: (_, api, __) => Row(
          children: [
            Expanded(
              child: _Card(
                number: api.worldLatest?.deathsTotal,
                number2: api.worldLatest?.deathsNew,
                title: 'Worldwide deaths:',
                title2: 'In the last 24h: ',
              ),
            ),
            Expanded(
              child: _Card(
                number: api.worldLatest?.casesTotal,
                number2: api.worldLatest?.casesNew,
                title: 'Total cases:',
                title2: 'New cases: ',
              ),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  final int number;
  final int number2;
  final String title;
  final String title2;

  const _Card({
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
                Text(title),
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
      duration: const Duration(seconds: 2),
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