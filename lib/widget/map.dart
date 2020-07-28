import 'dart:math';

import 'package:covid19/api/worldSvg.dart';
import 'package:flutter/material.dart';

class MapWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        child: RepaintBoundary(child: CustomPaint(painter: _Painter())),
        padding: const EdgeInsets.all(8),
      );
}

class MapData extends ChangeNotifier {}

class _Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    final ratio = kWorldSvgWidth / kWorldSvgHeight;
    var width = size.width;
    var height = width / ratio;
    if (height > size.height) {
      height = size.height;
      width = height * ratio;
    }

    canvas.translate((size.width - width) / 2, (size.height - height) / 2);
    canvas.scale(width / kWorldSvgWidth, height / kWorldSvgHeight);

    for (final countryCode in kWorldSvgCountries.keys) {
      _paint(canvas, paint, kWorldSvgCountries[countryCode].split(' '));
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) => false;

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
