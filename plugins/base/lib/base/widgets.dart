import 'package:flutter/material.dart';

/// loading提示
class Loading extends StatelessWidget {
  final double size;
  final Size frameSize;

  const Loading({this.size = 15.0, this.frameSize = const Size.square(30.0)});

  @override
  Widget build(BuildContext context) {
    final inner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Colors.grey),
      ),
    );
    if (frameSize == null) return inner;
    return Container(
      alignment: Alignment.center,
      width: frameSize.width,
      height: frameSize.height,
      child: inner,
    );
  }
}

/// 搜索标题栏
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String hint;

  final Future<void> Function(String) onConfirm;

  SearchAppBar({this.hint = '请输入搜索内容', @required this.onConfirm});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  _SearchAppBarState createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    final searchTextStyle = Theme.of(context).textTheme.bodyText2;
    return AppBar(
      titleSpacing: 0.0,
      title: Container(
        height: 40.0,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000.0),
          ),
        ),
        child: TextField(
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
            hintText: widget.hint,
            hintStyle: searchTextStyle.copyWith(color: Colors.grey),
          ),
          style: searchTextStyle,
          onSubmitted: (_) => _onConfirm(),
          onChanged: (text) => _text = text,
        ),
      ),
      actions: [
        TextButton(
          child: Text('搜索', style: TextStyle(color: Colors.white)),
          onPressed: _onConfirm,
        )
      ],
    );
  }

  void _onConfirm() {
    widget.onConfirm(_text).then((value) {
      // TODO
    });
  }
}
