import 'package:flutter/foundation.dart';

@immutable
class Layout {
  static const kRequiredWidthForBoth = 600;

  final bool showNew;
  final bool showTotal;

  const Layout._(this.showNew, this.showTotal);

  bool get showBoth => showNew && showTotal;
}

const layoutTotal = Layout._(false, true);
const layoutNew = Layout._(true, false);
const layoutBoth = Layout._(true, true);
