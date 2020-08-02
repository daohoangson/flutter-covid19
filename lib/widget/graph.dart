import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
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

  var _maxX = 0.0;
  var _maxY = 0.0;
  List<Rect> _rects;
  List<Offset> _points;

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

    _prePaint();

    final scaleX = _maxX > 0 ? size.width / _maxX : 1;
    final scaleY = _maxY > 0 ? size.height / _maxY : 1;
    switch (mode) {
      case GraphMode.bar:
        canvas.save();

        // with a single transformation, we are doing three things:
        // - vertical flip
        // - scaling
        // - and finally a downward move (because of the flip)
        canvas.transform(Float64List.fromList([
          scaleX, // scaling
          0,
          0,
          0,
          0,
          -scaleY, // flip and scaling
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          size.height, // downward move
          0,
          1
        ]));

        for (final rect in _rects) {
          final value = rect.bottom.toInt();
          final paint = _paints[sort.calculateSeriousness(value: value)];
          canvas.drawRect(rect, paint);
        }

        canvas.restore();
        break;
      case GraphMode.line:
        canvas.drawPoints(
          PointMode.polygon,
          _points
              .map((p) => Offset(p.dx * scaleX, size.height - p.dy * scaleY))
              .toList(growable: false),
          _paints[sort.calculateSeriousness(record: country.latest)],
        );
        break;
    }

    Timeline.finishSync();
  }

  @override
  bool shouldRepaint(_Painter other) =>
      country.code != other.country.code ||
      mode != other.mode ||
      sort != other.sort;

  void _prePaint() {
    switch (mode) {
      case GraphMode.bar:
        if (_rects != null) return;
        _rects = [];
        break;
      case GraphMode.line:
        if (_points != null) return;
        _points = [Offset(0, 0)];
        break;
    }

    DateTime x0;
    for (final record in country.records) {
      x0 ??= record.date;
      final x = record.date.difference(x0).inDays.toDouble();
      if (x < 0) continue;

      final y = sort.measure(record).toDouble();
      switch (mode) {
        case GraphMode.bar:
          _rects.add(Rect.fromLTRB(x - 1, 0, x, y));
          break;
        case GraphMode.line:
          _points.add(Offset(x, y));
          break;
      }

      _maxX = max(_maxX, x);
      _maxY = max(_maxY, y);
    }
  }

  static final _paints = kColors
      .map((color) => Paint()
        ..color = color.withOpacity(.75)
        ..strokeWidth = 2)
      .toList(growable: false);
}

enum GraphMode {
  bar,
  line,
}
