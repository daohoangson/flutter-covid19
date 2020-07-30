import 'package:covid19/api/api.dart';
import 'package:covid19/api/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/widget/graph.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TableWidget extends StatefulWidget {
  @override
  _TableState createState() => _TableState();
}

class _TableState extends State<TableWidget> {
  SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, app, __) => api.hasData
            ? SafeArea(
                child: LayoutBuilder(
                builder: (_, bc) => _buildTable(
                  api,
                  app,
                  bc.maxWidth > 600
                      ? _layoutBoth
                      : app.order.isNew ? _layoutNew : _layoutTotal,
                ),
              ))
            : Text(api.error?.toString() ??
                'API data is unavailable. Please try again later'),
      );

  Widget _buildTable(Api api, AppState app, _Layout layout) {
    final order = app.order;
    if (_sortedOrder != order) {
      _sortedList = order.sort(api.countries);
      _sortedOrder = order;
    }

    return Column(children: [
      Row(children: [
        layout.showBoth
            ? const Expanded(child: SizedBox.shrink())
            : Expanded(child: _buildTotalNewToggler(order)),
        if (layout.showTotal) _buildHeader(deathsTotal, order, layout),
        if (layout.showNew) _buildHeader(deathsNew, order, layout),
        if (layout.showTotal) _buildHeader(casesTotal, order, layout),
        if (layout.showNew) _buildHeader(casesNew, order, layout),
      ]),
      Expanded(
        child: _ListView(
          countries: _sortedList,
          highlight: app.highlight,
          highlighter: app.highlighter,
          layout: layout,
        ),
      ),
    ]);
  }

  Widget _buildTotalNewToggler(SortOrder order) => InkWell(
        child: Text(
          order.isNew ? '(total / NEW)' : '(TOTAL / new)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.caption,
          textAlign: TextAlign.right,
        ),
        onTap: () => AppState.of(context).order = order.flipNewTotal(),
      );

  Widget _buildHeader(SortOrderPair pair, SortOrder order, _Layout layout) =>
      InkWell(
        child: _NumberBox(
          child: _NumberText(
            (order == pair.asc ? '↑ ' : order == pair.desc ? '↓ ' : '') +
                (layout.showBoth ? pair.header : pair.headerCasesDeaths),
          ),
        ),
        onTap: () => AppState.of(context).order = pair.flipAscDesc(order),
      );
}

@immutable
class _Layout {
  final bool showNew;
  final bool showTotal;

  const _Layout(this.showNew, this.showTotal);

  bool get showBoth => showNew && showTotal;
}

const _layoutTotal = _Layout(false, true);
const _layoutNew = _Layout(true, false);
const _layoutBoth = _Layout(true, true);

class _ListView extends StatefulWidget {
  final List<ApiCountry> countries;
  final ApiCountry highlight;
  final Highlighter highlighter;
  final _Layout layout;

  const _ListView({
    @required this.countries,
    this.highlight,
    this.highlighter,
    Key key,
    @required this.layout,
  }) : super(key: key);

  @override
  _ListState createState() => _ListState();
}

class _ListState extends State<_ListView> {
  final _controller = ItemScrollController();

  @override
  Widget build(BuildContext context) => ScrollablePositionedList.builder(
        itemBuilder: (_, index) => _buildCountry(
          country: widget.countries[index],
          number: index + 1,
        ),
        itemCount: widget.countries.length,
        itemScrollController: _controller,
      );

  @override
  void didUpdateWidget(_ListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final needsScrolling = false ||
        // 1. Someone else (not us) changed the highlight country
        (widget.highlight != oldWidget.highlight &&
            widget.highlighter != Highlighter.table) ||
        // 2. Sort order has been changed
        (widget.countries != oldWidget.countries);

    if (needsScrolling) {
      // let's scroll to make sure the highlighed is visible
      final index = widget.highlight != null
          ? widget.countries.indexOf(widget.highlight)
          : 0;
      _controller.scrollTo(
        index: index.clamp(0, widget.countries.length - 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    }
  }

  Widget _buildCountry({ApiCountry country, int number}) => InkWell(
        child: Row(
          children: [
            Expanded(child: _buildName(number, country)),
            if (widget.layout.showTotal)
              _buildNumber(
                country: country,
                graphMode: GraphMode.line,
                sop: deathsTotal,
              ),
            if (widget.layout.showNew)
              _buildNumber(
                country: country,
                data: '+${_formatNumber(country.latest.deathsNew)}',
                graphMode: GraphMode.bar,
                sop: deathsNew,
              ),
            if (widget.layout.showTotal)
              _buildNumber(
                country: country,
                graphMode: GraphMode.line,
                sop: casesTotal,
              ),
            if (widget.layout.showNew)
              _buildNumber(
                country: country,
                data: '+${_formatNumber(country.latest.casesNew)}',
                graphMode: GraphMode.bar,
                sop: casesNew,
              ),
          ],
        ),
        onTap: () =>
            AppState.of(context).setHighlight(Highlighter.table, country),
      );

  Widget _buildName(int number, ApiCountry country) => Padding(
        child: Text(
          '$number. ${country.name}',
          style: country == widget.highlight
              ? TextStyle(fontWeight: FontWeight.bold)
              : null,
        ),
        padding: const EdgeInsets.all(8),
      );

  Widget _buildNumber({
    ApiCountry country,
    String data,
    GraphMode graphMode,
    SortOrderPair sop,
  }) {
    final record = country.latest;
    final sort = sop.asc;
    final color = kColors[sort.calculateSeriousness(record)];

    return _NumberBox(
      child: Padding(
        child: Stack(
          children: [
            _NumberText(
              data ?? _formatNumber(sort.measure(record)),
              color: color,
            ),
            Positioned.fill(
              child: GraphWidget(
                color: color,
                id: "${country.code}-${sop.hashCode}",
                measureFn: sort.measure,
                mode: graphMode,
                records: country.records,
              ),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
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
          overflow: TextOverflow.fade,
          style: Theme.of(context).textTheme.caption.copyWith(color: color),
        ),
        padding: const EdgeInsets.all(8),
      );
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
