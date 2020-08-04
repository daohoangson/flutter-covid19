import 'package:covid19/data/api.dart';
import 'package:covid19/data/sort.dart';
import 'package:covid19/app_state.dart';
import 'package:covid19/layout.dart';
import 'package:covid19/widget/toggler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TableWidget extends StatefulWidget {
  static const kMinWidth = _NumberBox.kWidth * 5;

  @override
  _TableState createState() => _TableState();
}

class _TableState extends State<TableWidget> {
  SortOrder _sortedOrder;
  List<ApiCountry> _sortedList;

  @override
  Widget build(BuildContext _) => Consumer2<Api, AppState>(
        builder: (_, api, app, __) => api.hasData
            ? LayoutBuilder(
                builder: (_, bc) => _buildTable(
                  api,
                  app,
                  bc.maxWidth > Layout.kRequiredWidthForBoth
                      ? layoutBoth
                      : app.order.isNew ? layoutNew : layoutTotal,
                ),
              )
            : Text(api.error?.toString() ??
                'API data is unavailable. Please try again later'),
      );

  Widget _buildTable(Api api, AppState app, Layout layout) {
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

  Widget _buildTotalNewToggler(SortOrder order) => Align(
        alignment: Alignment.centerRight,
        child: Tooltip(
          child: InkWell(
            child: TogglerWidget(
              optionTrue: 'New',
              optionFalse: 'Total',
              value: order.isNew,
            ),
            onTap: () => AppState.of(context).order = order.flipNewTotal(),
          ),
          message: 'Toggle between Total and New numbers',
        ),
      );

  Widget _buildHeader(SortOrderPair pair, SortOrder order, Layout layout) =>
      Tooltip(
        child: InkWell(
          child: _NumberBox(
            child: _NumberText(
              (layout.showBoth ? pair.header : pair.headerCasesDeaths) +
                  (order == pair.asc ? ' ↑' : order == pair.desc ? ' ↓' : ''),
            ),
          ),
          onTap: () => AppState.of(context).order = pair.flipAscDesc(order),
        ),
        message: 'Sort by ${pair.headerCasesDeaths}',
      );
}

class _ListView extends StatefulWidget {
  final List<ApiCountry> countries;
  final ApiCountry highlight;
  final Highlighter highlighter;
  final Layout layout;

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
  void initState() {
    super.initState();
    _makeSureHighlightIsVisible(false);
  }

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

    if (
        // 1. Someone else (not us) changed the highlight country
        (widget.highlight != oldWidget.highlight &&
                widget.highlighter != Highlighter.table) ||
            // 2. Sort order has been changed
            (widget.countries != oldWidget.countries)) {
      _makeSureHighlightIsVisible(true);
    }
  }

  Widget _buildCountry({ApiCountry country, int number}) => InkWell(
        child: Row(
          children: [
            Expanded(child: _buildName(number, country)),
            if (widget.layout.showTotal)
              _buildNumber(country: country, sop: deathsTotal),
            if (widget.layout.showNew)
              _buildNumber(
                country: country,
                data: '+${_formatNumber(country.latest.deathsNew)}',
                sop: deathsNew,
              ),
            if (widget.layout.showTotal)
              _buildNumber(country: country, sop: casesTotal),
            if (widget.layout.showNew)
              _buildNumber(
                country: country,
                data: '+${_formatNumber(country.latest.casesNew)}',
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

  Widget _buildNumber({ApiCountry country, String data, SortOrderPair sop}) =>
      _NumberBox(
        child: _NumberText(
          data ?? _formatNumber(sop.asc.measure(country.latest)),
        ),
      );

  void _makeSureHighlightIsVisible(bool animate) {
    final index = (widget.highlight != null
            ? widget.countries.indexOf(widget.highlight)
            : 0)
        .clamp(0, widget.countries.length - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) => animate
        ? _controller.scrollTo(
            index: index, duration: const Duration(milliseconds: 500))
        : _controller.jumpTo(index: index));
  }
}

class _NumberBox extends StatelessWidget {
  static const kWidth = 75.0;

  final Widget child;

  const _NumberBox({this.child, Key key}) : super(key: key);

  @override
  Widget build(BuildContext _) => SizedBox(child: child, width: kWidth);
}

class _NumberText extends StatelessWidget {
  final String data;

  const _NumberText(
    this.data, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Padding(
        child: Text(
          data,
          maxLines: 1,
          overflow: TextOverflow.fade,
          style: Theme.of(context).textTheme.caption,
        ),
        padding: const EdgeInsets.all(8),
      );
}

String _formatNumber(int v) => NumberFormat.compact().format(v);
