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
  double canvasScale;
  Offset canvasTranslate;
  AnimationController controller;
  Offset focalPoint;
  Animation<Offset> focalPointAnimation;
  ApiCountry highlightPrev;
  double scale = 1.0;
  Animation<double> scaleAnimation;

  Offset _onScaleLastLocalFocalPoint;
  double _onScaleBaseScale;

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

            focalPointAnimation = null;
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
        child: GestureDetector(
          child: CustomPaint(
            painter: _Painter(
              canvasScale: canvasScale,
              canvasTranslate: canvasTranslate,
              countries: widget.countries,
              focalPoint: focalPointAnimation?.value ?? focalPoint,
              highlight: widget.highlight,
              highlightOpacity: controller.value,
              highlightPrev: highlightPrev,
              legend: Theme.of(context).textTheme.bodyText2.color,
              map: map,
              order: widget.order,
              progress: widget.progress,
              scale: scaleAnimation?.value ?? scale,
              size: widget.size,
            ),
          ),
          onDoubleTap: () => setState(() => scale = scale * 1.5),
          onScaleStart: (details) {
            _onScaleLastLocalFocalPoint = details.localFocalPoint;
            _onScaleBaseScale = scale;
          },
          onScaleUpdate: (details) => setState(() {
            if (_onScaleBaseScale != null) {
              scale = _onScaleBaseScale * details.scale;
            }

            if (_onScaleLastLocalFocalPoint != null) {
              final delta =
                  (details.localFocalPoint - _onScaleLastLocalFocalPoint) /
                      scale /
                      canvasScale;
              focalPoint = focalPoint - delta;
            }
            _onScaleLastLocalFocalPoint = details.localFocalPoint;
          }),
        ),
        size: widget.size,
      );

  @override
  void didUpdateWidget(MapPainter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlight != oldWidget.highlight ||
        widget.useHqMap != oldWidget.useHqMap ||
        widget.size != oldWidget.size) {
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    final ratio = map.width / map.height;
    var width = widget.size.width;
    var height = width / ratio;
    if (height > widget.size.height) {
      height = widget.size.height;
      width = height * ratio;
    }

    canvasTranslate = Offset(
        (widget.size.width - width) / 2, (widget.size.height - height) / 2);
    canvasScale = width / map.width;

    final code = widget.highlight?.code;
    final rect = map.getCountryByCode(code)?.rect;
    final focalBegin = focalPointAnimation?.value ?? focalPoint ?? centerPoint;
    focalPoint = rect?.center ?? centerPoint;
    focalPointAnimation = Tween<Offset>(
      begin: focalBegin,
      end: focalPoint,
    ).animate(controller);

    final scaleBegin = scaleAnimation?.value ?? scale;
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
  final double canvasScale;
  final Offset canvasTranslate;
  final Iterable<ApiCountry> countries;
  final Offset focalPoint;
  final ApiCountry highlight;
  final double highlightOpacity;
  final ApiCountry highlightPrev;
  final Color legend;
  final SvgMap map;
  final SortOrder order;
  final Paint paint0;
  final double progress;
  final double scale;
  final Size size;

  _Painter({
    @required this.canvasScale,
    @required this.canvasTranslate,
    this.countries,
    this.focalPoint,
    this.highlight,
    this.highlightOpacity,
    this.highlightPrev,
    @required this.legend,
    @required this.map,
    this.order,
    this.progress,
    this.scale,
    @required this.size,
  }) : paint0 = Paint()
          ..color = legend
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size _) {
    Timeline.startSync('Covid-19 map', arguments: {
      'hasCountries': countries != null,
      'scale': scale,
    });

    canvas.save();

    canvas.translate(canvasTranslate.dx, canvasTranslate.dy);
    canvas.scale(canvasScale, canvasScale);

    if (focalPoint != null)
      canvas.translate(
        (map.width / 2 - focalPoint.dx * scale),
        (map.height / 2 - focalPoint.dy * scale),
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
      focalPoint != other.focalPoint ||
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
