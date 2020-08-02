import 'dart:developer';
import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/api/world_svg.dart' as world_svg;
import 'package:covid19/app_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

const kMapPreferredRatio = world_svg.kWidth / world_svg.kHeight;

class MapProgressIndicator extends StatelessWidget {
  final double value;

  const MapProgressIndicator({Key key, @required this.value}) : super(key: key);

  @override
  Widget build(BuildContext _) => Padding(
        child: LayoutBuilder(
          builder: (_, bc) => _CustomPaint(
            progress: value,
            size: bc.biggest,
          ),
        ),
        padding: const EdgeInsets.all(8),
      );
}

class MapWidget extends StatelessWidget {
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

  const _CustomPaint({
    this.countries,
    this.highlight,
    Key key,
    this.order,
    this.progress = 1,
    @required this.size,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CustomPaintState();
}

class _CustomPaintState extends State<_CustomPaint>
    with TickerProviderStateMixin {
  static const centerPoint =
      Offset(world_svg.kWidth / 2, world_svg.kHeight / 2);

  AnimationController _controller;

  Animation<Offset> focusPoint;
  Animation<double> scale;

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
            focusPoint: focusPoint?.value ?? centerPoint,
            highlight: widget.highlight,
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

    if (widget.highlight != oldWidget.highlight) _resetAnimation();
  }

  void _resetAnimation() {
    final code = widget.highlight?.code;
    final rect = world_svg.getCountryByCode(code)?.rect;
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
  final SortOrder order;
  final double progress;
  final double scale;

  _Painter({
    this.countries,
    this.focusPoint,
    this.highlight,
    this.order,
    this.progress,
    this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Timeline.startSync('Covid-19 map', arguments: {
      'hasCountries': countries != null,
      'scale': scale,
    });

    final ratio = world_svg.kWidth / world_svg.kHeight;
    var width = size.width;
    var height = width / ratio;
    if (height > size.height) {
      height = size.height;
      width = height * ratio;
    }

    canvas.save();

    canvas.translate((size.width - width) / 2, (size.height - height) / 2);
    canvas.scale(width / world_svg.kWidth, height / world_svg.kHeight);

    canvas.translate(
      (world_svg.kWidth / 2 - focusPoint.dx * scale),
      (world_svg.kHeight / 2 - focusPoint.dy * scale),
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
        _paintCountry(canvas, _paints[0], highlight.code);
      }
    } else {
      final codes = world_svg.getAvailableCountryCodes();
      var i = 0;
      for (final code in codes) {
        _paintCountry(canvas, _paints[0], code);
        i++;

        if (progress < 1 && i / codes.length > progress) {
          break;
        }
      }
    }

    canvas.restore();

    if (countries != null && highlight == null) {
      for (var i = 1; i < _paints.length; i++) {
        _paintLegend(canvas, size, i, order.seriousnessValues[i - 1]);
      }
    }

    Timeline.finishSync();
  }

  @override
  bool shouldRepaint(_Painter other) =>
      ((countries == null) != (other.countries == null)) ||
      focusPoint != other.focusPoint ||
      highlight != other.highlight ||
      order != other.order ||
      progress != other.progress ||
      scale != other.scale;

  static final _legendValueFormatter = intl.NumberFormat.compact();

  static final _paints = <Paint>[
    Paint()
      ..color = kColors[0]
      ..style = PaintingStyle.stroke,
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

  static void _paintCountry(Canvas canvas, Paint paint, String code) {
    final path = world_svg.getCountryByCode(code)?.path;
    if (path == null) return;

    canvas.drawPath(path, paint);
  }

  static void _paintLegend(
    Canvas canvas,
    Size size,
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
            color: Colors.black,
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
