import 'package:flutter/material.dart';

class FlagWidget extends StatefulWidget {
  final String iso;

  const FlagWidget(this.iso, {Key key}) : super(key: key);

  @override
  _FlagState createState() => _FlagState();
}

class _FlagState extends State<FlagWidget> {
  static const kPreferredHeight = 24.0;
  static const kPreferredWidth = 32.0;

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
            ? Image(
                image: image,
                fit: BoxFit.cover,
              )
            : imageOk == false ? Text(widget.iso) : null,
        height: kPreferredHeight,
        width: kPreferredWidth,
      );
}
