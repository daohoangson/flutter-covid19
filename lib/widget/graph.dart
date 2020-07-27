import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatelessWidget {
  final Color color;
  final String id;
  final int Function(ApiRecord) measureFn;
  final GraphMode mode;
  final Iterable<ApiRecord> records;

  const GraphWidget({
    @required this.color,
    @required this.id,
    Key key,
    @required this.measureFn,
    @required this.mode,
    @required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _Painter(
          color: color,
          id: id,
          measureFn: measureFn,
          mode: mode,
          records: records,
        ),
      );
}

class _Painter extends CustomPainter {
  final Color color;
  final String id;
  final int Function(ApiRecord) measureFn;
  final GraphMode mode;
  final Iterable<ApiRecord> records;

  _Painter({
    @required this.color,
    @required this.id,
    @required this.measureFn,
    @required this.mode,
    @required this.records,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final x0 = DateTime(2020, 2, 24);
    final now = DateTime.now();
    final xUpper = DateTime(now.year, now.month, now.day).difference(x0).inDays;

    var yUpper = 0;
    final values = <int, int>{};
    for (final record in records) {
      final x = record.date.difference(x0).inDays;
      final y = measureFn(record);

      values[x] = y;
      yUpper = max(yUpper, y);
    }
    if (yUpper == 0) return;

    final paint = Paint()
      ..color = color.withOpacity(.75)
      ..strokeWidth = 2;
    final xScale = size.width / xUpper;
    final yScale = size.height / yUpper;

    var prev = Offset(0, size.height);
    for (var x = 0; x < xUpper; x++) {
      final y = values[x] ?? 0;
      final offset = Offset(x * xScale, size.height - y * yScale);

      switch (mode) {
        case GraphMode.BAR:
          canvas.drawRect(
              Rect.fromLTRB(prev.dx, offset.dy, offset.dx, size.height), paint);
          break;
        case GraphMode.LINE:
          canvas.drawLine(prev, offset, paint);
          break;
      }

      prev = offset;
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) =>
      id != oldDelegate.id || mode != oldDelegate.mode;
}

enum GraphMode {
  BAR,
  LINE,
}