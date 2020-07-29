import 'dart:math';

import 'package:covid19/api/api.dart';
import 'package:covid19/api/world_svg.dart' as world_svg;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Consumer2<Api, MapData>(
        builder: (_, api, data, __) => Padding(
          child: CustomPaint(
            painter: _Painter(
              countries: api.hasData ? api.countries : null,
              highlight: data._highlightCountryCode,
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

class _Painter extends CustomPainter {
  final Iterable<ApiCountry> countries;
  final String highlight;

  _Painter({
    this.countries,
    this.highlight,
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

    if (countries != null) {
      for (final country in countries) {
        final commands = world_svg.getCommandsByCountryCode(country.code);
        final seriousness = (log(country.latest.casesTotal) / log(2))
            .clamp(1, _paints.length - 1)
            .toInt();
        final paint = (highlight == null || highlight == country.code)
            ? _paints[seriousness]
            : _paints[0];
        _paint(canvas, paint, commands);
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
      highlight != other.highlight;

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
