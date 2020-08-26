import 'dart:developer';
import 'dart:math';

import 'package:covid19/data/api.dart';
import 'package:covid19/data/sort.dart';
import 'package:covid19/data/svg.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class MapPainter extends StatefulWidget {
  final Iterable<ApiCountry> countries;
  final ApiCountry highlight;
  final SortOrder order;
  final double progress;
  final Size size;
  final bool useHqMap;

  MapPainter({
    this.countries,
    this.highlight,
    Key key,
    this.order,
    this.progress = 1,
    @required this.size,
    this.useHqMap = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MapState();
}

class _MapState extends State<MapPainter> with TickerProviderStateMixin {
  AnimationController controller;
  Offset focusPoint;
  Animation<Offset> focusPointAnimation;
  ApiCountry highlightPrev;
  double scale;
  Animation<double> scaleAnimation;

  Offset get centerPoint => Offset(map.width / 2, map.height / 2);
  SvgMap get map => widget.useHqMap == true ? hqMap : sdMap;

  @override
  initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..addListener(() => setState(() {
          if (controller.isCompleted) {
            highlightPrev = widget.highlight;

            focusPointAnimation = null;
            scaleAnimation = null;
          }
        }));

    _resetAnimation();
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
        child: CustomPaint(
          painter: _Painter(
            countries: widget.countries,
            focusPoint: focusPointAnimation?.value ?? focusPoint,
            highlight: widget.highlight,
            highlightOpacity: controller.value,
            highlightPrev: highlightPrev,
            legend: Theme.of(context).textTheme.bodyText2.color,
            map: map,
            order: widget.order,
            progress: widget.progress,
            scale: scaleAnimation?.value ?? scale ?? 1.0,
          ),
        ),
        size: widget.size,
      );

  @override
  void didUpdateWidget(MapPainter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlight != oldWidget.highlight ||
        widget.useHqMap != oldWidget.useHqMap) {
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    final code = widget.highlight?.code;
    final rect = map.getCountryByCode(code)?.rect;
    final focusBegin = focusPointAnimation?.value ?? focusPoint ?? centerPoint;
    focusPoint = rect?.center ?? centerPoint;
    focusPointAnimation = Tween<Offset>(
      begin: focusBegin,
      end: focusPoint,
    ).animate(controller);

    final scaleBegin = scaleAnimation?.value ?? scale ?? 1.0;
    scale = rect != null ? _calculateScaleToFit(rect, widget.size) : 1.0;
    scaleAnimation = Tween<double>(
      begin: scaleBegin,
      end: scale,
    ).animate(controller);

    controller
      ..reset()
      ..forward();
  }

  static double _calculateScaleToFit(Rect rect, Size size) {
    final ratio = rect.width / rect.height;
    var width = size.width;
    var height = width / ratio;
    if (height > size.height) {
      height = size.height;
      width = height * ratio;
    }

    return (width / rect.width).truncateToDouble().clamp(1.0, 10.0);
  }
}

class _Painter extends CustomPainter {
  final Iterable<ApiCountry> countries;
  final Offset focusPoint;
  final ApiCountry highlight;
  final double highlightOpacity;
  final ApiCountry highlightPrev;
  final Color legend;
  final SvgMap map;
  final SortOrder order;
  final Paint paint0;
  final double progress;
  final double scale;

  _Painter({
    this.countries,
    this.focusPoint,
    this.highlight,
    this.highlightOpacity,
    this.highlightPrev,
    @required this.legend,
    @required this.map,
    this.order,
    this.progress,
    this.scale,
  }) : paint0 = Paint()
          ..color = legend
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    Timeline.startSync('Covid-19 map', arguments: {
      'hasCountries': countries != null,
      'scale': scale,
    });

    final ratio = map.width / map.height;
    var width = size.width;
    var height = width / ratio;
    if (height > size.height) {
      height = size.height;
      width = height * ratio;
    }

    canvas.save();

    canvas.translate((size.width - width) / 2, (size.height - height) / 2);
    canvas.scale(width / map.width, height / map.height);

    if (focusPoint != null)
      canvas.translate(
        (map.width / 2 - focusPoint.dx * scale),
        (map.height / 2 - focusPoint.dy * scale),
      );
    if (scale != 1) canvas.scale(scale);

    if (countries != null) {
      _paintCountry(canvas, paint0, highlight?.code);
      _paintCountry(canvas, paint0, highlightPrev?.code);

      for (final country in countries) {
        final seriousness = order.calculateSeriousness(record: country.latest);
        final paint = highlight == null
            ? _paints[seriousness]
            : country == highlight
                ? (Paint()
                  ..color = kColors[seriousness].withOpacity(
                      highlightPrev == null ? 1 : highlightOpacity))
                : country == highlightPrev
                    ? (Paint()
                      ..color = kColors[seriousness]
                          .withOpacity(1 - highlightOpacity))
                    : paint0;
        _paintCountry(canvas, paint, country.code);
      }
    } else {
      final codes = map.getAvailableCountryCodes();
      var i = 0;
      for (final code in codes) {
        _paintCountry(canvas, paint0, code);
        i++;

        if (progress < 1 && i / codes.length > progress) {
          break;
        }
      }
    }

    canvas.restore();

    if (countries != null && highlight == null) {
      for (var i = 1; i < _paints.length; i++) {
        _paintLegend(canvas, size, legend, i, order.seriousnessValues[i - 1]);
      }
    }

    Timeline.finishSync();
  }

  @override
  bool shouldRepaint(_Painter other) =>
      ((countries == null) != (other.countries == null)) ||
      focusPoint != other.focusPoint ||
      highlight != other.highlight ||
      legend != other.legend ||
      map != other.map ||
      order != other.order ||
      progress != other.progress ||
      scale != other.scale;

  void _paintCountry(Canvas canvas, Paint paint, String code) {
    if (code == null) return;

    final path = map.getCountryByCode(code)?.path;
    if (path == null) return;

    canvas.drawPath(path, paint);
  }

  static final _legendValueFormatter = intl.NumberFormat.compact();

  static final _paints = <Paint>[
    null,
    Paint()..color = kColors[1],
    Paint()..color = kColors[2],
    Paint()..color = kColors[3],
    Paint()..color = kColors[4],
    Paint()..color = kColors[5],
    Paint()..color = kColors[6],
    Paint()..color = kColors[7],
    Paint()..color = kColors[8],
    Paint()..color = kColors[9],
    Paint()..color = kColors[10],
  ];

  static void _paintLegend(
    Canvas canvas,
    Size size,
    Color color,
    int level,
    int value,
  ) {
    final left = 0.0;
    final legendHeight = min(16.0, size.height / 10 / 2);
    final legendWidth = legendHeight / 2;
    final padding = legendWidth / 4;
    final top = size.height - (legendHeight + padding) * level;
    final rect = Rect.fromLTWH(left, top, legendWidth, legendHeight);
    final paint = _paints[level];
    canvas.drawRect(rect, paint);

    if (value > -1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: _legendValueFormatter.format(value),
          style: TextStyle(
            color: color,
            fontSize: legendHeight * .75,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          left + legendWidth + padding,
          top + (legendHeight - textPainter.height) / 2,
        ),
      );
    }
  }
}
