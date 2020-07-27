import 'package:covid19/api/api.dart';
import 'package:covid19/widget/graph.dart';
import 'package:covid19/widget/map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DataTableWidget extends StatefulWidget {
  @override
  _DataTableState createState() => _DataTableState();
}

class _DataTableState extends State<DataTableWidget> {
  _SortOrder order = _SortOrder.deathsDesc;

  _SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer<Api>(
        builder: (_, api, __) => api.isLoading
            ? Center(
                child: CircularProgressIndicator(
                value: kIsWeb ? null : api.progress,
              ))
            : api.hasData
                ? SafeArea(
                    child: LayoutBuilder(
                    builder: (_, bc) =>
                        _buildTable(api, showNew: bc.maxWidth > 600),
                  ))
                : Text(api.error.toString()),
      );

  Widget _buildTable(Api api, {bool showNew}) {
    if (_sortedOrder != order) {
      _sortedList = [...api.countries];
      _sortedList.sort((country1, country2) {
        var cmp = 0;
        final a = country1.latest;
        final b = country2.latest;

        switch (order) {
          case _SortOrder.casesAsc:
            cmp = a.casesTotal.compareTo(b.casesTotal);
            if (cmp == 0) {
              cmp = a.deathsTotal.compareTo(b.deathsTotal);
            }
            break;
          case _SortOrder.casesDesc:
            cmp = b.casesTotal.compareTo(a.casesTotal);
            if (cmp == 0) {
              cmp = b.deathsTotal.compareTo(a.deathsTotal);
            }
            break;
          case _SortOrder.deathsAsc:
            cmp = a.deathsTotal.compareTo(b.deathsTotal);
            if (cmp == 0) {
              cmp = a.casesTotal.compareTo(b.casesTotal);
            }
            break;
          case _SortOrder.deathsDesc:
            cmp = b.deathsTotal.compareTo(a.deathsTotal);
            if (cmp == 0) {
              cmp = b.casesTotal.compareTo(a.casesTotal);
            }
            break;
        }

        return cmp;
      });
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const SizedBox(width: _FlagWidget.WIDTH),
        const Expanded(child: SizedBox.shrink()),
        _Header(
          (order == _SortOrder.deathsAsc
                  ? '↑ '
                  : order == _SortOrder.deathsDesc ? '↓ ' : '') +
              'Deaths',
          onTap: () => setState(() => order = order == _SortOrder.deathsDesc
              ? _SortOrder.deathsAsc
              : _SortOrder.deathsDesc),
        ),
        if (showNew) _NumberBox(),
        _Header(
          (order == _SortOrder.casesAsc
                  ? '↑ '
                  : order == _SortOrder.casesDesc ? '↓ ' : '') +
              'Cases',
          onTap: () => setState(() => order = order == _SortOrder.casesDesc
              ? _SortOrder.casesAsc
              : _SortOrder.casesDesc),
        ),
        if (showNew) _NumberBox(),
      ]),
      Expanded(
        child: ImplicitlyAnimatedList<ApiCountry>(
          areItemsTheSame: (a, b) => a.code == b.code,
          itemBuilder: (_, animation, country, ___) => SizeTransition(
            child: _DataRow(
              country: country,
              showNew: showNew,
              worldLatest: api.worldLatest,
            ),
            sizeFactor: animation,
          ),
          items: _sortedList,
        ),
      ),
    ]);
  }
}

class _DataRow extends StatelessWidget {
  final ApiCountry country;
  final bool showNew;
  final ApiRecord worldLatest;

  const _DataRow({
    Key key,
    this.country,
    this.showNew,
    this.worldLatest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        _FlagWidget(country.code, key: ValueKey(country.code)),
        Expanded(
          child: InkWell(
            child: Padding(
              child: Text(country.name),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onTap: () => MapData.of(context).animateCamera(country.code),
          ),
        ),
        _NumberWidget(
          color: Colors.red,
          country: country,
          graphMode: GraphMode.LINE,
          measureFn: (record) => record.deathsTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.orange,
            country: country,
            data: '+${_formatNumber(country.latest.deathsNew)}',
            graphMode: GraphMode.BAR,
            measureFn: (record) => record.deathsNew,
          ),
        _NumberWidget(
          color: Colors.green,
          country: country,
          graphMode: GraphMode.LINE,
          measureFn: (record) => record.casesTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.lime,
            country: country,
            data: '+${_formatNumber(country.latest.casesNew)}',
            graphMode: GraphMode.BAR,
            measureFn: (record) => record.casesNew,
          ),
      ]);
}

class _Header extends StatelessWidget {
  final String data;
  final VoidCallback onTap;

  const _Header(this.data, {Key key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
        child: _NumberBox(child: _NumberText(data)),
        onTap: onTap,
      );
}

class _FlagWidget extends StatefulWidget {
  static const HEIGHT = 24.0;
  static const WIDTH = 32.0;

  final String iso;

  const _FlagWidget(this.iso, {Key key}) : super(key: key);

  @override
  _FlagState createState() => _FlagState();
}

class _FlagState extends State<_FlagWidget> {
  bool imageOk;

  ImageProvider get image =>
      AssetImage('gosquared/flags/flags-iso/flat/32/${widget.iso}.png');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    imageOk = null;
    precacheImage(
      image,
      context,
      onError: (_, __) => mounted ? setState(() => imageOk = false) : null,
    ).then((_) =>
        mounted && imageOk == null ? setState(() => imageOk = true) : null);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        child: imageOk == true
            ? Image(image: image)
            : imageOk == false
                ? Icon(Icons.warning, size: _FlagWidget.HEIGHT)
                : null,
        height: _FlagWidget.HEIGHT,
        width: _FlagWidget.WIDTH,
      );
}

class _NumberBox extends StatelessWidget {
  final Widget child;

  const _NumberBox({this.child, Key key}) : super(key: key);

  @override
  Widget build(BuildContext _) => SizedBox(child: child, width: 75);
}

class _NumberText extends StatelessWidget {
  final Color color;
  final String data;

  const _NumberText(
    this.data, {
    this.color,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        child: Text(
          data,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.caption.copyWith(color: color),
        ),
        padding: const EdgeInsets.all(8),
      );
}

class _NumberWidget extends StatelessWidget {
  final Color color;
  final ApiCountry country;
  final String data;
  final GraphMode graphMode;
  final int Function(ApiRecord) measureFn;

  _NumberWidget({
    @required this.color,
    @required this.country,
    String data,
    Key key,
    @required this.graphMode,
    @required this.measureFn,
  })  : data = data ?? _formatNumber(measureFn(country.latest)),
        super(key: key);

  @override
  Widget build(BuildContext context) => _NumberBox(
        child: Stack(
          children: [
            _NumberText(data, color: color),
            Positioned.fill(
              child: GraphWidget(
                color: color,
                id: "${country.code}-${measureFn(country.latest)}",
                measureFn: measureFn,
                mode: graphMode,
                records: country.records,
              ),
            ),
          ],
        ),
      );
}

enum _SortOrder {
  casesAsc,
  casesDesc,
  deathsAsc,
  deathsDesc,
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
