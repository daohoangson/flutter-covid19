import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/api/world_svg.dart' as world_svg;
import 'package:covid19/app_state.dart';
import 'package:flutter/material.dart';
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
                    onPressed: () => app.setHighlight(Highlighter.search, null),
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
      duration: const Duration(milliseconds: 500),
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
    final rect = _getCountryRect(code);
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

    return world_svg.kWidth / width;
  }

  static Rect _getCountryRect(String countryCode) {
    final commands = world_svg.getCommandsByCountryCode(countryCode);
    if (commands.isEmpty) return null;

    Offset prev;
    double xMin, xMax, yMin, yMax;
    Rect bestRect;

    for (final command in commands) {
      switch (command.type) {
        case world_svg.CommandType.l:
          final offset = prev + command.offset;
          prev = offset;
          xMin = min(xMin, offset.dx);
          xMax = max(xMax, offset.dx);
          yMin = min(yMin, offset.dy);
          yMax = max(yMax, offset.dy);
          break;
        case world_svg.CommandType.m:
          final offset = (prev ?? Offset(0, 0)) + command.offset;
          prev = offset;
          xMin = xMax = offset.dx;
          yMin = yMax = offset.dy;
          break;
        case world_svg.CommandType.z:
          final rect = Rect.fromLTRB(xMin, yMin, xMax, yMax);
          if (bestRect == null ||
              rect.width * rect.height > bestRect.width * bestRect.height) {
            bestRect = rect;
          }
          break;
      }
    }

    return bestRect;
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
    final ratio = world_svg.kWidth / world_svg.kHeight;
    var width = size.width;
    var height = width / ratio;
    if (height > size.height) {
      height = size.height;
      width = height * ratio;
    }

    canvas.translate((size.width - width) / 2, (size.height - height) / 2);
    canvas.scale(width / world_svg.kWidth, height / world_svg.kHeight);

    canvas.translate(
      (world_svg.kWidth / 2 - focusPoint.dx * scale),
      (world_svg.kHeight / 2 - focusPoint.dy * scale),
    );
    if (scale != 1) canvas.scale(scale);

    if (countries != null) {
      for (final country in countries) {
        final seriousness = (log(order.measure(country.latest)) / log(2))
            .clamp(1, _paints.length - 1)
            .toInt();
        _paint(canvas, _paints[seriousness], country.code);
      }

      if (highlight != null) {
        _paint(canvas, _paints[0], highlight.code);
      }
    } else {
      final codes = world_svg.getAvailableCountryCodes();
      var i = 0;
      for (final code in codes) {
        _paint(canvas, _paints[0], code);
        i++;

        if (progress < 1 && i / codes.length > progress) {
          break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Painter other) =>
      ((countries == null) != (other.countries == null)) ||
      focusPoint != other.focusPoint ||
      highlight != other.highlight ||
      order != other.order ||
      progress != other.progress ||
      scale != other.scale;

  static final _paints = <Paint>[
    Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke,
    Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.lime
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.lime
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.lime
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[300]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[300]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.yellow[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.orange[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.orange[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.orange[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.orange[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[500]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[700]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[900]
      ..style = PaintingStyle.fill,
    Paint()
      ..color = Colors.red[900]
      ..style = PaintingStyle.fill,
  ];

  static void _paint(Canvas canvas, Paint paint, String countryCode) {
    final commands = world_svg.getCommandsByCountryCode(countryCode);

    var pathCount = 0;
    List<Offset> points;
    double xMin, xMax, yMin, yMax;

    for (final command in commands) {
      switch (command.type) {
        case world_svg.CommandType.l:
          final offset = points.last + command.offset;
          points.add(offset);
          xMin = min(xMin, offset.dx);
          xMax = max(xMax, offset.dx);
          yMin = min(yMin, offset.dy);
          yMax = max(yMax, offset.dy);
          break;
        case world_svg.CommandType.m:
          final offset =
              (points?.isNotEmpty == true ? points.last : Offset(0, 0)) +
                  command.offset;
          points = [offset];
          xMin = xMax = offset.dx;
          yMin = yMax = offset.dy;
          break;
        case world_svg.CommandType.z:
          if (pathCount > 0) {
            final area = (xMax - xMin) * (yMax - yMin);
            if (area < 50) {
              // skip drawing path if the area is too small (practially invisible)
              // without the check, we were drawing up to 1.5k paths
              // currently we are only drawing 300 of those
              continue;
            }
          }

          final path = Path();
          path.addPolygon(points, true);
          canvas.drawPath(path, paint);

          pathCount++;
          break;
      }
    }
  }
}
