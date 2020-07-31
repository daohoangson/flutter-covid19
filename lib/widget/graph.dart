import 'dart:developer';
import 'dart:math';
import 'dart:ui';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:flutter/material.dart';

class GraphWidget extends StatelessWidget {
  final ApiCountry country;
  final GraphMode mode;
  final SortOrder sort;

  const GraphWidget({
    @required this.country,
    Key key,
    @required this.mode,
    @required this.sort,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _Painter(
          country: country,
          mode: mode,
          sort: sort,
        ),
      );
}

class _Painter extends CustomPainter {
  final ApiCountry country;
  final GraphMode mode;
  final SortOrder sort;

  _Painter({
    @required this.country,
    @required this.mode,
    @required this.sort,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Timeline.startSync('Covid-19 graph', arguments: {
      'country': country.code,
      'mode': mode == GraphMode.bar ? 'bar' : 'line',
      'sort': sort.toString(),
    });

    final x0 = DateTime(2020, 2, 24);
    final now = DateTime.now();
    final xUpper = DateTime(now.year, now.month, now.day).difference(x0).inDays;
    final data = _PaintingData(
      mode: mode,
      size: size,
      xScale: size.width / xUpper,
    );

    for (final record in country.records) {
      final x = record.date.difference(x0).inDays;
      if (x < 0) continue;

      final y = sort.measure(record);
      _drawPoint(data, x, y);
    }

    canvas.save();
    canvas.rotate(pi);
    canvas.translate(-size.width, -size.height);

    final paint = _paints[sort.calculateSeriousness(country.latest)];
    final scale = size.height / data.yMax;
    if (data.path != null) {
      canvas.save();
      if (scale < 1) canvas.scale(1, scale);
      canvas.drawPath(data.path, paint);
      canvas.restore();
    } else {
      canvas.drawPoints(
        PointMode.polygon,
        data.points.map((p) => p.scale(1, scale)).toList(growable: false),
        paint,
      );
    }

    canvas.restore();

    Timeline.finishSync();
  }

  @override
  bool shouldRepaint(_Painter other) =>
      country.code != other.country.code ||
      mode != other.mode ||
      sort != other.sort;

  static final _paints = kColors
      .map((color) => Paint()
        ..color = color
        ..strokeWidth = 2)
      .toList(growable: false);

  static void _drawPoint(_PaintingData data, int x, int y) {
    // we are drawing backward from the top right corner
    // the canvas will be rotated later to fix the graph direction
    // this is done to simplify the y scaling logic
    // we already know [_PaintingData.xScale] before hand so x axis is easy
    final offset = Offset(data.size.width - x * data.xScale, y * 1.0);

    if (data.path != null) {
      // bar mode
      final r = Rect.fromLTRB(offset.dx - data.xScale, 0, offset.dx, offset.dy);
      data.path.addRect(r);
    } else {
      // line mode
      data.points.add(offset);
    }

    data.prev = offset;
    data.yMax = max(data.yMax, y);
  }
}

enum GraphMode {
  bar,
  line,
}

class _PaintingData {
  final Path path;
  final List<Offset> points;
  Offset prev;
  final Size size;
  final double xScale;
  var yMax = 1;

  _PaintingData({
    @required GraphMode mode,
    @required this.size,
    @required this.xScale,
  })  : path = mode == GraphMode.bar ? Path() : null,
        points = mode == GraphMode.bar ? null : [Offset(size.width, 0)],
        prev = Offset(size.width, 0);
}
