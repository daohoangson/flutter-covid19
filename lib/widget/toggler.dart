import 'dart:math';

import 'package:flutter/material.dart';

class TogglerWidget extends StatefulWidget {
  final String optionTrue;
  final String optionFalse;
  final bool value;

  const TogglerWidget({
    Key key,
    @required this.optionTrue,
    @required this.optionFalse,
    @required this.value,
  }) : super(key: key);

  @override
  _TogglerState createState() => _TogglerState();
}

class _TogglerState extends State<TogglerWidget> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          Opacity(
            child: Padding(
              child: Text('${widget.optionTrue}${widget.optionFalse}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            opacity: 0,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _Painter(
                animationIsRunning: _controller.isAnimating,
                animationValue: _controller.value,
                overText: widget.value ? widget.optionTrue : widget.optionFalse,
                overStyle: DefaultTextStyle.of(context).style,
                underText:
                    widget.value ? widget.optionFalse : widget.optionTrue,
                underStyle: Theme.of(context).textTheme.caption,
              ),
            ),
          ),
        ],
      );

  @override
  void didUpdateWidget(TogglerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _controller
        ..reset()
        ..forward();
    }
  }
}

class _Painter extends CustomPainter {
  final bool animationIsRunning;
  final double animationValue;
  final String overText;
  final TextStyle overStyle;
  final String underText;
  final TextStyle underStyle;

  _Painter({
    this.animationIsRunning,
    this.animationValue,
    @required this.overText,
    @required this.overStyle,
    @required this.underText,
    @required this.underStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isFlipping = animationIsRunning == true && animationValue < 0.5;
    final animation = animationIsRunning == true
        ? (animationValue < 0.5 ? 3 * animationValue : 1 - animationValue)
        : 0.0;

    final over = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: isFlipping ? underText : overText,
        style: overStyle,
      ),
    );
    over.layout();

    final under = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: isFlipping ? overText : underText,
        style: underStyle,
      ),
    );
    under.layout();

    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);
    final topLeft = Offset(0, 0);
    final topRight = Offset(size.width, 0);
    final lineBottom = Offset(min(over.width, under.width) / 2, size.height);
    final lineTop = Offset(size.width, min(over.height, under.height) / 2);

    canvas.save();
    canvas.clipPath(Path()
      ..addPolygon(
          [lineTop, topRight, bottomRight, bottomLeft, lineBottom], true));
    under.paint(
      canvas,
      Offset(
        (size.width - under.width) / 2 + under.width * (.5 - animation),
        (size.height - under.height) / 2 + under.height * .25,
      ),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(Path()
      ..addPolygon([topLeft, topRight, lineTop, lineBottom, bottomLeft], true));
    over.paint(
      canvas,
      Offset(
        (size.width - over.width) / 2 - over.width * (-animation),
        (size.height - over.height) / 2 - over.height * .25,
      ),
    );
    canvas.restore();

    canvas.drawLine(lineTop, lineBottom, Paint()..color = underStyle.color);
  }

  @override
  bool shouldRepaint(_Painter other) =>
      animationIsRunning != other.animationIsRunning ||
      animationValue != other.animationValue ||
      overText != other.overText ||
      overStyle != other.overStyle ||
      underText != other.underText ||
      underStyle != other.underStyle;
}
