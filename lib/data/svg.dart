import 'dart:math';

import 'package:covid19/data/svg/mapsvg.dart' as _mapsvg;
import 'package:covid19/data/svg/simplemaps.dart' as _simplemaps;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class SvgMap {
  final double height;
  final double width;

  final _cache = Map<String, SvgCountry>();
  final Map<String, String> _paths;

  SvgMap._(
    this._paths, {
    @required this.height,
    @required this.width,
  });

  Iterable<String> getAvailableCountryCodes() => _paths.keys;

  SvgCountry getCountryByCode(String code) {
    if (_cache.containsKey(code)) {
      return _cache[code];
    }

    final path = Path();
    if (!_paths.containsKey(code)) {
      return null;
    }

    final parts = _paths[code].split(' ');
    final i = parts.iterator;

    List<Offset> points;
    double xMin, xMax, yMin, yMax;
    Rect largest;

    while (i.moveNext()) {
      final part = i.current;
      switch (part) {
        case 'M':
        case 'm':
          if (i.moveNext()) {
            final offset = ((points?.isNotEmpty == true && part == 'm')
                    ? points.last
                    : Offset(0, 0)) +
                _parseOffset(i.current);
            points = [offset];
            xMin = xMax = offset.dx;
            yMin = yMax = offset.dy;
          }
          break;
        case 'l':
          break;
        case 'z':
          final rect = Rect.fromLTRB(xMin, yMin, xMax, yMax);
          if (largest == null ||
              rect.width * rect.height > largest.width * largest.height) {
            largest = rect;
          }

          path.addPolygon(points, true);
          break;
        default:
          final offset = points.last + _parseOffset(part);
          points.add(offset);
          xMin = min(xMin, offset.dx);
          xMax = max(xMax, offset.dx);
          yMin = min(yMin, offset.dy);
          yMax = max(yMax, offset.dy);
      }
    }

    _cache[code] = SvgCountry._(path, largest);
    return _cache[code];
  }

  static Offset _parseOffset(String str) {
    final l = str.split(',');
    return Offset(double.parse(l[0]), double.parse(l[1]));
  }
}

class SvgCountry {
  final Path path;
  final Rect rect;

  SvgCountry._(this.path, this.rect);
}

final hqMap = SvgMap._(
  _mapsvg.kPaths,
  height: _mapsvg.kHeight,
  width: _mapsvg.kWidth,
);

final sdMap = SvgMap._(
  _simplemaps.kPaths,
  height: _simplemaps.kHeight,
  width: _simplemaps.kWidth,
);
