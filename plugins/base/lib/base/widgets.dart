import 'package:base/base/pub.dart';
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
  StreamControllerWithData<bool> _controller;
  FocusNode _focusNode;

  @override
  void initState() {
    _controller = StreamControllerWithData(false);
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          focusNode: _focusNode,
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
        StreamBuilder<bool>(
          initialData: false,
          stream: _controller.stream,
          builder: (context, snapshot) => snapshot.data
              ? TextButton(
                  child: Row(
                    children: [
                      Text('搜索', style: TextStyle(color: Colors.white54)),
                      Container(
                        margin: const EdgeInsets.only(left: 5.0, top: 2.0),
                        width: 8.0,
                        height: 8.0,
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.white54,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ],
                  ),
                  onPressed: null,
                )
              : TextButton(
                  child: Text('搜索', style: TextStyle(color: Colors.white)),
                  onPressed: _onConfirm,
                ),
        ),
      ],
    );
  }

  void _onConfirm() {
    if (_focusNode.hasFocus) _focusNode.unfocus();
    _controller.add(true);
    widget.onConfirm(_text).then((_) => _controller.add(false));
  }
}
