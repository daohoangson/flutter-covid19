import 'package:covid19/app_state.dart';
import 'package:covid19/data/api.dart';
import 'package:covid19/widget/map/painter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MapWidget extends StatelessWidget {
  MapWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (context, api, app, _) => Padding(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (_, bc) => MapPainter(
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
