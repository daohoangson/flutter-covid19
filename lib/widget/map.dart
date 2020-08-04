import 'dart:developer';
import 'dart:math';

import 'package:covid19/data/api.dart';
import 'package:covid19/data/sort.dart';
import 'package:covid19/data/svg.dart';
import 'package:covid19/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

class MapProgressIndicator extends StatelessWidget {
  final double value;

  const MapProgressIndicator({Key key, @required this.value}) : super(key: key);

  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (_, useHqMap, __) => Padding(
          child: LayoutBuilder(
            builder: (_, bc) => _CustomPaint(
              progress: value,
              size: bc.biggest,
              useHqMap: useHqMap,
            ),
          ),
          padding: const EdgeInsets.all(8),
        ),
        selector: (_, app) => app.useHqMap,
      );
}

class MapWidget extends StatelessWidget {
  MapWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (context, api, app, _) => Padding(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (_, bc) => _CustomPaint(
                  countries: api.hasData ? api.countries : null,
                  highlight: app.highlight,
                  order: app.order,
                  size: bc.biggest,
                  useHqMap: app.useHqMap,
                ),
              ),
              if (app.highlight != null)
                Positioned.directional(
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => app.setHighlight(Highlighter.map, null),
                    tooltip: 'Close',
                  ),
                  start: 0,
                  textDirection: Directionality.of(context),
                ),
            ],
          ),
          padding: const EdgeInsets.all(8),
        ),
      );
}

class _CustomPaint extends StatefulWidget {
  final Iterable<ApiCountry> countries;
  final ApiCountry highlight;
  final SortOrder order;
  final double progress;
  final Size size;
  final bool useHqMap;

  _CustomPaint({
    this.countries,
    this.highlight,
    Key key,
    this.order,
    this.progress = 1,
    @required this.size,
    this.useHqMap = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomPaintState();
}

class _CustomPaintState extends State<_CustomPaint>
    with TickerProviderStateMixin {
  AnimationController _controller;

  Animation<Offset> focusPoint;
  Animation<double> scale;

  Offset get centerPoint => Offset(map.width / 2, map.height / 2);
  SvgMap get map => widget.useHqMap == true ? hqMap : sdMap;

  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
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
  Widget build(BuildContext context) => SizedBox.fromSize(
        child: CustomPaint(
          painter: _Painter(
            countries: widget.countries,
            focusPoint: focusPoint?.value,
            highlight: widget.highlight,
            legend: Theme.of(context).textTheme.bodyText2.color,
            map: map,
            order: widget.order,
            progress: widget.progress,
            scale: scale?.value ?? 1,
          ),
        ),
        size: widget.size,
      );

  @override
  void didUpdateWidget(_CustomPaint oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlight != oldWidget.highlight ||
        widget.useHqMap != oldWidget.useHqMap) {
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    final code = widget.highlight?.code;
    final rect = map.getCountryByCode(code)?.rect;
    final focusBegin = focusPoint?.value ?? centerPoint;
    final focusEnd = rect != null ? rect.center : centerPoint;
    focusPoint = Tween<Offset>(
      begin: focusBegin,
      end: focusEnd,
    ).animate(_controller);

    final scaleBegin = scale?.value ?? 1.0;
    final scaleEnd =
        rect != null ? _calculateScaleToFit(rect, widget.size) : 1.0;
    scale = Tween<double>(
      begin: scaleBegin,
      end: scaleEnd,
    ).animate(_controller);

    _controller
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
      for (final country in countries) {
        final seriousness = order
            .calculateSeriousness(record: country.latest)
            .clamp(0, _paints.length - 1);
        _paintCountry(canvas, _paints[seriousness], country.code);
      }

      if (highlight != null) {
        _paintCountry(canvas, paint0, highlight.code);
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
    final path = map.getCountryByCode(code)?.path;
    if (path == null) return;

    canvas.drawPath(path, paint);
  }

  static final _legendValueFormatter = intl.NumberFormat.compact();

  static final _paints = <Paint>[
    null,
    Paint()
      ..color = kColors[1]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[2]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[3]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[4]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[5]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[6]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[7]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[8]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[9]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = kColors[10]
      ..style = PaintingStyle.fill,
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
