import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/api/world_svg.dart' as world_svg;
import 'package:covid19/widget/table.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Consumer3<Api, MapData, TableData>(
        builder: (_, api, data, table, __) => Padding(
          child: LayoutBuilder(
            builder: (_, bc) => _CustomPaint(
              countries: api.hasData ? api.countries : null,
              highlight: data._highlightCountryCode,
              order: table.order,
              size: bc.biggest,
            ),
          ),
          padding: const EdgeInsets.all(8),
        ),
      );
}

class MapData extends ChangeNotifier {
  String _highlightCountryCode;
  set highlightCountryCode(String code) {
    if (code == _highlightCountryCode) {
      _highlightCountryCode = null;
    } else {
      _highlightCountryCode = code;
    }

    notifyListeners();
  }

  static MapData of(BuildContext context) =>
      Provider.of<MapData>(context, listen: false);
}

class _CustomPaint extends StatefulWidget {
  final Iterable<ApiCountry> countries;
  final String highlight;
  final SortOrder order;
  final Size size;

  const _CustomPaint({
    this.countries,
    this.highlight,
    Key key,
    this.order,
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
            order: widget.order,
            scale: scale?.value ?? 1,
          ),
        ),
        size: widget.size,
      );

  @override
  void didUpdateWidget(_CustomPaint oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlight != oldWidget.highlight) {
      final code = widget.highlight;
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

    final i = commands.iterator;
    while (i.moveNext()) {
      final command = i.current;
      switch (command) {
        case 'm':
          if (i.moveNext()) {
            final offset =
                (prev ?? Offset(0, 0)) + _Painter._parseOffset(i.current);
            prev = offset;
            xMin = xMax = offset.dx;
            yMin = yMax = offset.dy;
          }
          break;
        case 'z':
          final rect = Rect.fromLTRB(xMin, yMin, xMax, yMax);
          if (bestRect == null ||
              rect.width * rect.height > bestRect.width * bestRect.height) {
            bestRect = rect;
          }
          break;
        default:
          final offset = prev + _Painter._parseOffset(command);
          prev = offset;
          xMin = min(xMin, offset.dx);
          xMax = max(xMax, offset.dx);
          yMin = min(yMin, offset.dy);
          yMax = max(yMax, offset.dy);
      }
    }

    return bestRect;
  }
}

class _Painter extends CustomPainter {
  final Iterable<ApiCountry> countries;
  final Offset focusPoint;
  final SortOrder order;
  final double scale;

  _Painter({
    this.countries,
    this.focusPoint,
    this.order,
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
        final commands = world_svg.getCommandsByCountryCode(country.code);
        final seriousness = (log(order.measure(country.latest)) / log(2))
            .clamp(1, _paints.length - 1)
            .toInt();
        _paint(canvas, _paints[seriousness], commands);
      }
    } else {
      for (final code in world_svg.getAvailableCountryCodes()) {
        _paint(canvas, _paints[0], world_svg.getCommandsByCountryCode(code));
      }
    }
  }

  @override
  bool shouldRepaint(_Painter other) =>
      ((countries == null) != (other.countries == null)) ||
      focusPoint != other.focusPoint ||
      order != other.order ||
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

  static void _paint(Canvas canvas, Paint paint, Iterable<String> commands) {
    var pathCount = 0;
    List<Offset> points;
    double xMin, xMax, yMin, yMax;

    final i = commands.iterator;
    while (i.moveNext()) {
      final command = i.current;
      switch (command) {
        case 'm':
          if (i.moveNext()) {
            final offset =
                (points?.isNotEmpty == true ? points.last : Offset(0, 0)) +
                    _parseOffset(i.current);
            points = [offset];
            xMin = xMax = offset.dx;
            yMin = yMax = offset.dy;
          }
          break;
        case 'z':
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
        default:
          final offset = points.last + _parseOffset(command);
          points.add(offset);
          xMin = min(xMin, offset.dx);
          xMax = max(xMax, offset.dx);
          yMin = min(yMin, offset.dy);
          yMax = max(yMax, offset.dy);
      }
    }
  }

  static Offset _parseOffset(String str) {
    final parts = str.split(',');
    assert(parts.length == 2);

    final dx = double.parse(parts[0]);
    final dy = double.parse(parts[1]);
    return Offset(dx, dy);
  }
}
