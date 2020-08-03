import 'dart:math';

import 'package:covid19/data/api.dart';
import 'package:covid19/layout.dart';
import 'package:covid19/screen/settings.dart';
import 'package:covid19/search.dart';
import 'package:covid19/widget/big_numbers.dart';
import 'package:covid19/widget/map.dart';
import 'package:covid19/widget/table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  static const kRouteName = '/';

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Consumer<Api>(
      builder: (_, api, child) => _AnimatedLoadingWidget(
        child: child,
        isLoading: api.isLoading,
        progressIndicator: _ProgressIndicator(value: api.progress),
      ),
      child: Scaffold(
        appBar: !kIsWeb
            ? AppBar(
                actions: [
                  CountrySearchButton.icon(),
                  SettingsScreen.icon(),
                ],
                title: Text('Covid-19'),
              )
            : null,
        body: screenSize.width < screenSize.height
            ? _Portrait()
            : _Landscape(screenSize: screenSize),
        floatingActionButton: kIsWeb ? CountrySearchButton.fab() : null,
      ),
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  final double value;

  const _ProgressIndicator({Key key, this.value}) : super(key: key);

  String get loadingText {
    if (value != null) {
      if (value < .5) return 'Loading.\u{00a0}\u{00a0}';
      if (value < .6) return 'Loading..\u{00a0}';
      if (value < .7) return 'Loading...';
      if (value < .8) return 'Loading.\u{00a0}\u{00a0}';
      if (value < .85) return 'Loading..\u{00a0}';
      if (value < .9) return 'Loading...';
      if (value < 1.0) return 'Almost done...';
    }

    return 'Loading...';
  }

  @override
  Widget build(BuildContext context) {
    final map = AspectRatio(
      aspectRatio: 16 / 9,
      child: kIsWeb
          ? const Center(child: CircularProgressIndicator())
          : MapProgressIndicator(value: value),
    );

    if (value >= 1) return map;

    return Stack(
      children: [
        map,
        Positioned(
          bottom: 22,
          child: Text(
            loadingText,
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
          left: 0,
          right: 0,
        ),
      ],
    );
  }
}

class _AnimatedLoadingWidget extends StatefulWidget {
  static final mapKey = GlobalKey();

  final Widget child;
  final bool isLoading;
  final Widget progressIndicator;

  const _AnimatedLoadingWidget({
    @required this.child,
    Key key,
    @required this.isLoading,
    @required this.progressIndicator,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AnimatedLoadingState();
}

class _AnimatedLoadingState extends State<_AnimatedLoadingWidget>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _opacity;
  RelativeRect _rect0;
  Animation<RelativeRect> _rectAnimation;

  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addListener(() => setState(() {}));

    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted || (!widget.isLoading && _rect0 == null))
      return widget.child;

    if (!widget.isLoading)
      return Container(
        child: Stack(
          children: [
            Opacity(
              child: widget.child,
              opacity: _opacity.value,
            ),
            _rectAnimation != null
                ? PositionedTransition(
                    child: Opacity(
                      child: widget.progressIndicator,
                      opacity: 1 - _opacity.value,
                    ),
                    rect: _rectAnimation,
                  )
                : Positioned.fromRelativeRect(
                    child: widget.progressIndicator,
                    rect: _rect0,
                  ),
          ],
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      );

    return Scaffold(
      body: Center(
        child: Container(
          child: widget.progressIndicator,
          key: _AnimatedLoadingWidget.mapKey,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(_AnimatedLoadingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLoading != oldWidget.isLoading) {
      final mapKey = _AnimatedLoadingWidget.mapKey;
      final oldMap = _findRect(mapKey.currentContext);
      final self = _findRect(context);

      if (oldMap != null && self != null) {
        _rect0 = RelativeRect.fromRect(oldMap, self);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newMap = _findRect(mapKey.currentContext);
          if (newMap == null) return;

          _rectAnimation = RelativeRectTween(
            begin: _rect0,
            end: RelativeRect.fromRect(newMap, self),
          ).animate(_controller);

          _controller
            ..reset()
            ..forward();
        });
      }
    }
  }

  static Rect _findRect(BuildContext context) {
    final ro = context?.findRenderObject();
    if (ro is! RenderBox) return null;

    final rb = ro as RenderBox;
    final position = rb.localToGlobal(Offset.zero);
    final size = rb.size;

    return Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
  }
}

class _Portrait extends StatelessWidget {
  @override
  Widget build(BuildContext _) => Stack(
        children: [
          Column(
            children: [
              BigNumbersPlaceholder(),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: MapWidget(key: _AnimatedLoadingWidget.mapKey),
              ),
              Expanded(child: TableWidget()),
            ],
          ),
          Positioned(child: BigNumbersWidget()),
        ],
      );
}

class _Landscape extends StatelessWidget {
  final Size screenSize;

  const _Landscape({Key key, this.screenSize}) : super(key: key);

  @override
  Widget build(BuildContext _) {
    var mapAspectRatio = 1.0;
    var mapWidth = screenSize.height;
    var tableWidth = screenSize.width - mapWidth;
    if (tableWidth < TableWidget.kMinWidth) {
      tableWidth = TableWidget.kMinWidth * 1.1;
      mapWidth = screenSize.width - tableWidth;
      mapAspectRatio = mapWidth / screenSize.height;
    }

    if (mapWidth > Layout.kRequiredWidthForBoth) {
      return _buildWide(mapAspectRatio);
    }

    return _buildNormal(mapAspectRatio);
  }

  Widget _buildNormal(double mapAspectRatio) => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: mapAspectRatio,
              child: MapWidget(key: _AnimatedLoadingWidget.mapKey),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (_, bc) => Column(
                  children: [
                    BigNumbersWidget(bc: bc),
                    Expanded(child: TableWidget()),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildWide(double mapAspectRatio) => SafeArea(
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: mapAspectRatio,
              child: Stack(
                children: [
                  Column(
                    children: [
                      BigNumbersPlaceholder(),
                      Expanded(
                        child: MapWidget(key: _AnimatedLoadingWidget.mapKey),
                      ),
                    ],
                  ),
                  Positioned(child: BigNumbersWidget()),
                ],
              ),
            ),
            Expanded(child: TableWidget()),
          ],
        ),
      );
}
