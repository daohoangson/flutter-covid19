import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/widget/graph.dart';
import 'package:covid19/widget/map.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TableWidget extends StatefulWidget {
  @override
  _TableState createState() => _TableState();
}

class TableData extends ChangeNotifier {
  SortOrder __order = deathsTotalDesc;
  SortOrder get order => __order;
  set _order(SortOrder v) {
    if (v == __order) return;
    __order = v;
    notifyListeners();
  }

  static TableData of(BuildContext context) =>
      Provider.of<TableData>(context, listen: false);
}

class _TableState extends State<TableWidget> {
  SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer2<Api, TableData>(
        builder: (_, api, data, __) => api.isLoading
            ? Center(
                child: CircularProgressIndicator(
                value: kIsWeb ? null : api.progress,
              ))
            : api.hasData
                ? SafeArea(
                    child: LayoutBuilder(
                    builder: (_, bc) => _buildTable(api, data.order,
                        showNew: bc.maxWidth > 600),
                  ))
                : Text(api.error.toString()),
      );

  Widget _buildTable(Api api, SortOrder order, {bool showNew}) {
    if (_sortedOrder != order) {
      _sortedList = order.sort(api.countries);
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        const SizedBox(width: _FlagWidget.WIDTH),
        const Expanded(child: SizedBox.shrink()),
        _Header(
          (order == deathsTotalAsc
                  ? '↑ '
                  : order == deathsTotalDesc ? '↓ ' : '') +
              'Deaths',
          onTap: () => setState(() => TableData.of(context)._order =
              order == deathsTotalDesc ? deathsTotalAsc : deathsTotalDesc),
        ),
        if (showNew) _NumberBox(),
        _Header(
          (order == casesTotalAsc
                  ? '↑ '
                  : order == casesTotalDesc ? '↓ ' : '') +
              'Cases',
          onTap: () => setState(() => TableData.of(context)._order =
              order == casesTotalDesc ? casesTotalAsc : casesTotalDesc),
        ),
        if (showNew) _NumberBox(),
      ]),
      Expanded(
        child: ListView.builder(
          itemBuilder: (_, index) => _DataRow(
            country: _sortedList[index],
            index: index,
            showNew: showNew,
          ),
          itemCount: _sortedList.length,
        ),
      ),
    ]);
  }
}

class _DataRow extends StatelessWidget {
  final ApiCountry country;
  final int index;
  final bool showNew;

  const _DataRow({
    @required this.country,
    @required this.index,
    Key key,
    this.showNew,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Row(children: [
        _FlagWidget(country.code, key: ValueKey(country.code)),
        Expanded(
          child: InkWell(
            child: Padding(
              child: Text('${index + 1}. ${country.name}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onTap: () =>
                MapData.of(context).highlightCountryCode = country.code,
          ),
        ),
        _NumberWidget(
          color: Colors.red,
          country: country,
          graphMode: GraphMode.line,
          measureFn: (record) => record.deathsTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.orange,
            country: country,
            data: '+${_formatNumber(country.latest.deathsNew)}',
            graphMode: GraphMode.bar,
            measureFn: (record) => record.deathsNew,
          ),
        _NumberWidget(
          color: Colors.green,
          country: country,
          graphMode: GraphMode.line,
          measureFn: (record) => record.casesTotal,
        ),
        if (showNew)
          _NumberWidget(
            color: Colors.lime,
            country: country,
            data: '+${_formatNumber(country.latest.casesNew)}',
            graphMode: GraphMode.bar,
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

String _formatNumber(int v) => NumberFormat.compact().format(v);
