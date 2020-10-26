import 'package:base/base/pub.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    widget.onConfirm(_text).then((_) {
      if (mounted) _controller.add(false);
    });
  }
}

/// 带缓存和loading的图片
class ImageWithUrl extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double width;
  final double height;
  final bool round;
  final void Function() onPressed;

  const ImageWithUrl(
    this.url, {
    this.fit = BoxFit.cover,
    this.onPressed,
    this.width,
    this.height,
    this.round = false,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      fit: fit,
      imageUrl: url,
      errorWidget: (context, url, error) => Icon(Icons.broken_image),
      progressIndicatorBuilder: (context, url, progress) => Center(
        child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(value: progress.progress)),
      ),
      imageBuilder: onPressed == null
          ? null
          : (context, imageProvider) => Container(
                width: width,
                height: height,
                clipBehavior: Clip.hardEdge,
                decoration: ShapeDecoration(
                  shape: round
                      ? CircleBorder()
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2.0),
                        ),
                  image: DecorationImage(image: imageProvider, fit: fit),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    highlightColor: Colors.black26,
                    splashColor: Colors.black26,
                    onTap: onPressed,
                  ),
                ),
              ),
    );
  }
}

/// 带图标的按钮
class ButtonWithIcon extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String text;
  final bool loading;
  final bool disabled;

  final Function() onPressed;

  const ButtonWithIcon({
    this.color,
    this.icon,
    this.text,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
  });

  @override
  _ButtonWithIconState createState() => _ButtonWithIconState();
}

class _ButtonWithIconState extends State<ButtonWithIcon> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    final loadingSize = theme.textTheme.bodyText1.fontSize * 0.75;
    if (widget.onPressed == null ||
        _loading ||
        widget.loading ||
        widget.disabled) {
      color = Colors.grey;
    } else {
      color = widget.color ?? theme.primaryColor;
    }
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) Icon(widget.icon, color: color),
        if (widget.icon != null || widget.text != null) Container(width: 5.0),
        if (widget.text != null)
          Text(widget.text, style: TextStyle(color: color)),
        if (_loading || widget.loading)
          Container(
            margin: const EdgeInsets.only(left: 5.0),
            width: loadingSize,
            height: loadingSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.grey),
            ),
          ),
      ],
    );
    child = Padding(
      child: child,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
    );
    return InkWell(
      child: child,
      onTap: widget.onPressed == null ||
              _loading ||
              widget.loading ||
              widget.disabled
          ? null
          : () {
              final result = widget.onPressed();
              if (result is Future) {
                if (!mounted) return;
                setState(() => _loading = true);
                result.then((_) {
                  if (mounted) setState(() => _loading = false);
                });
              }
            },
    );
  }
}

/// 底部加载更多显示
class LoadMore extends StatelessWidget {
  final bool noMore;

  const LoadMore({this.noMore});

  @override
  Widget build(BuildContext context) {
    var loadingSize = Theme.of(context).textTheme.bodyText1.fontSize * 0.75;
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(5.0),
      alignment: Alignment.center,
      child: noMore == true
          ? Text('没有更多数据了')
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[Loading(size: loadingSize), Text('加载中')],
            ),
    );
  }
}

/// 剧中显示的提示文字，比如暂无数据
class CenterInfoText extends StatelessWidget {
  final String text;

  const CenterInfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Text(text ?? '', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

/// 文字开关，类似 最新 / 最热
class TextSwitch extends StatefulWidget {
  final Duration animDuration;
  final String leftText, rightText;
  final void Function(bool) onChange;

  /// 状态，true:左边的文字、false:右边的文字
  final bool defaultStatus;

  TextSwitch({
    @required this.leftText,
    @required this.rightText,
    this.defaultStatus = true,
    this.animDuration = const Duration(milliseconds: 250),
    this.onChange,
  });

  @override
  _TextSwitchState createState() => _TextSwitchState();
}

class _TextSwitchState extends State<TextSwitch> {
  /// 状态，true:左边的文字、false:右边的文字
  bool status;

  @override
  void initState() {
    status = widget.defaultStatus;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textCaptionStyle = theme.textTheme.caption;
    final textPrimaryCaptionStyle =
        textCaptionStyle.copyWith(color: theme.primaryColor);
    return TextButton(
      onPressed: () {
        setState(() => status = !status);
        widget.onChange(status);
      },
      child: AnimatedSwitcher(
        duration: widget.animDuration,
        child: RichText(
          key: ValueKey(status),
          text: status
              ? TextSpan(
                  children: [
                    TextSpan(
                        text: '${widget.leftText} / ', style: textCaptionStyle),
                    TextSpan(
                        text: widget.rightText, style: textPrimaryCaptionStyle),
                  ],
                )
              : TextSpan(
                  children: [
                    TextSpan(
                        text: widget.leftText, style: textPrimaryCaptionStyle),
                    TextSpan(
                        text: ' / ${widget.rightText}',
                        style: textCaptionStyle),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 文字后边带loading
class TextWithLoading extends StatelessWidget {
  final String text;
  final bool loading;

  const TextWithLoading(this.text, this.loading);

  @override
  Widget build(BuildContext context) {
    return loading
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(text),
              Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.only(left: 5.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.grey),
                ),
              )
            ],
          )
        : Text(text);
  }
}
