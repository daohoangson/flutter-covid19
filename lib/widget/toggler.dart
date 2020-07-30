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

class _TogglerState extends State<TogglerWidget> {
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
}

class _Painter extends CustomPainter {
  final String overText;
  final TextStyle overStyle;
  final String underText;
  final TextStyle underStyle;

  _Painter({
    @required this.overText,
    @required this.overStyle,
    @required this.underText,
    @required this.underStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final over = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: overText,
        style: overStyle,
      ),
    );
    over.layout();

    final under = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: underText,
        style: underStyle,
      ),
    );
    under.layout();

    final bottomLeft = Offset(size.width, 0);
    final bottomRight = Offset(size.width, size.height);
    final topLeft = Offset(0, 0);
    final topRight = Offset(0, size.height);

    canvas.save();
    canvas.clipPath(
        Path()..addPolygon([topRight, bottomRight, bottomLeft], true));
    under.paint(
      canvas,
      Offset(
        (size.width - under.width) / 2 + under.width * .25,
        (size.height - under.height) / 2 + under.height * .25,
      ),
    );
    canvas.restore();

    canvas.save();
    canvas.clipPath(Path()..addPolygon([topLeft, topRight, bottomLeft], true));
    over.paint(
      canvas,
      Offset(
        (size.width - over.width) / 2 - over.width * .25,
        (size.height - over.height) / 2 - over.height * .25,
      ),
    );
    canvas.restore();

    canvas.drawLine(topRight, bottomLeft, Paint()..color = Colors.grey);
  }

  @override
  bool shouldRepaint(_Painter other) =>
      overText != other.overText ||
      overStyle != other.overStyle ||
      underText != other.underText ||
      underStyle != other.underStyle;
}
