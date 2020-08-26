import 'package:covid19/app_state.dart';
import 'package:covid19/widget/map/painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapProgressIndicator extends StatelessWidget {
  final double value;

  const MapProgressIndicator({Key key, @required this.value}) : super(key: key);

  @override
  Widget build(BuildContext _) => Selector<AppState, bool>(
        builder: (_, useHqMap, __) => Padding(
          child: LayoutBuilder(
            builder: (_, bc) => MapPainter(
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
