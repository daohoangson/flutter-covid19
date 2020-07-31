import 'package:flutter/material.dart';

class FlagWidget extends StatefulWidget {
  final String iso;

  const FlagWidget(this.iso, {Key key}) : super(key: key);

  @override
  _FlagState createState() => _FlagState();
}

class _FlagState extends State<FlagWidget> {
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
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 4 / 3,
        child: imageOk == true
            ? Image(
                image: image,
                fit: BoxFit.cover,
              )
            : imageOk == false ? Text(widget.iso) : null,
      );
}
