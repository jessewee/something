import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'extensions.dart';
import 'pub.dart';

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
  final bool local;
  final BoxFit fit;
  final double aspectRatio;
  final double width;
  final double height;
  final bool round;
  final Color backgroundColor;
  final Widget errorWidget;
  final void Function() onPressed;

  const ImageWithUrl(
    this.url, {
    this.local = false,
    this.fit = BoxFit.cover,
    this.onPressed,
    this.width,
    this.height,
    this.aspectRatio,
    this.round = false,
    this.backgroundColor,
    this.errorWidget = const Icon(Icons.broken_image),
  });

  @override
  Widget build(BuildContext context) {
    if (local) {
      final file = File(url);
      if (file.existsSync()) {
        return _buildContent(Image.file(file, fit: fit));
      } else {
        return _buildContent(errorWidget);
      }
    }
    return CachedNetworkImage(
      fit: fit,
      imageUrl: url.checkServerFileUrl(),
      errorWidget: (context, url, error) => _buildContent(errorWidget),
      progressIndicatorBuilder: (context, url, progress) => Center(
        child: _buildContent(
          Center(child: CircularProgressIndicator(value: progress.progress)),
        ),
      ),
      imageBuilder: (context, imageProvider) =>
          _buildContent(Image(image: imageProvider, fit: fit)),
    );
  }

  Widget _buildContent(Widget child) {
    Widget content = Container(
      width: width,
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: round
            ? CircleBorder()
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.0),
              ),
      ),
      child: onPressed == null
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                child,
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    highlightColor: Colors.black26,
                    splashColor: Colors.black26,
                    onTap: onPressed,
                  ),
                )
              ],
            ),
    );
    if (aspectRatio != null) {
      content = AspectRatio(aspectRatio: aspectRatio, child: content);
    }
    return content;
  }
}

/// 带图标的按钮
class NormalButton extends StatefulWidget {
  final Color backgroundColor;
  final Color color;
  final IconData icon;
  final String text;
  final double fontSize;
  final bool loading;
  final bool disabled;
  final EdgeInsetsGeometry padding;

  final Function() onPressed;

  const NormalButton({
    this.backgroundColor,
    this.color,
    this.icon,
    this.text,
    this.fontSize,
    this.loading = false,
    this.disabled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
    this.onPressed,
  });

  @override
  _NormalButtonState createState() => _NormalButtonState();
}

class _NormalButtonState extends State<NormalButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    Color backgroundColor;
    final fontSize = widget.fontSize ?? theme.textTheme.bodyText1.fontSize;
    final loadingSize = fontSize * 0.75;
    if (widget.onPressed == null ||
        _loading ||
        widget.loading ||
        widget.disabled) {
      color = Colors.grey;
      if (widget.backgroundColor != null)
        backgroundColor = widget.backgroundColor.withAlpha(150);
    } else {
      if (widget.backgroundColor != null)
        backgroundColor = widget.backgroundColor;
      color = backgroundColor == null
          ? (widget.color ?? theme.primaryColor)
          : Colors.white;
    }
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (widget.icon != null) Icon(widget.icon, color: color, size: 16.0),
        if (widget.icon != null || widget.text != null) Container(width: 5.0),
        if (widget.text != null)
          Text(
            widget.text,
            style: TextStyle(color: color, fontSize: fontSize),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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
    child = Container(
      alignment: Alignment.center,
      child: child,
      padding: widget.padding,
    );
    return Material(
      borderRadius: BorderRadius.circular(2.0),
      clipBehavior: Clip.hardEdge,
      color: backgroundColor,
      child: InkWell(
        child: child,
        highlightColor: Colors.black26,
        splashColor: Colors.black26,
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
      ),
    );
  }
}

/// 底部加载更多显示
class LoadMore extends StatelessWidget {
  /// 下滑到距离底部的一定高度后开始加载更多
  static const validHeight = 100;
  final bool noMore;

  const LoadMore({this.noMore});

  @override
  Widget build(BuildContext context) {
    var loadingSize = Theme.of(context).textTheme.bodyText1.fontSize * 0.75;
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 30.0),
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

/// 404页面
class NotFoundPage extends StatelessWidget {
  final String path;

  const NotFoundPage(this.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('页面未找到')),
      body: Center(child: Text('$path')),
    );
  }
}

/// 参数错误页面
class ParamErrorPage extends StatelessWidget {
  final dynamic arg;

  const ParamErrorPage(this.arg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('参数错误')),
      body: Center(child: Text('$arg')),
    );
  }
}

/// 带输入框的sheet
class TextFieldSheet extends StatefulWidget {
  static Future<String> show(
    BuildContext context, {
    String defaultText = '',
    int maxLength = 500,
    Function(String) onConfirmClick,
  }) {
    return showModalBottomSheet<String>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => TextFieldSheet(
        defaultText: defaultText,
        maxLength: maxLength,
        onConfirmClick: onConfirmClick,
      ),
    );
  }

  final int maxLength;
  final String defaultText;
  final Function(String) onConfirmClick;

  TextFieldSheet({
    this.defaultText = '',
    this.maxLength = 500,
    this.onConfirmClick,
  });

  @override
  _TextFieldSheetState createState() => _TextFieldSheetState();
}

class _TextFieldSheetState extends State<TextFieldSheet> {
  TextEditingController _controller;
  StreamControllerWithData<bool> _btnStreamController;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.defaultText);
    _btnStreamController =
        StreamControllerWithData(widget.defaultText?.isNotEmpty == true);
    _controller.addListener(() {
      if (_controller.text.isEmpty && _btnStreamController.value) {
        _btnStreamController.add(false);
      } else if (_controller.text.isNotEmpty && !_btnStreamController.value) {
        _btnStreamController.add(true);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _btnStreamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 顶行
    Widget top = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // 取消按钮
        NormalButton(
          text: '取消',
          padding: const EdgeInsets.all(15.0),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // 确定按钮
        StreamBuilder<Object>(
          initialData: _btnStreamController.value,
          stream: _btnStreamController.stream,
          builder: (context, snapshot) => NormalButton(
            padding: const EdgeInsets.all(15.0),
            text: '确定',
            disabled: snapshot.data != true,
            onPressed: () async {
              if (widget.onConfirmClick != null) {
                final result = widget.onConfirmClick(_controller.text);
                if (result is Future) {
                  final tmp = await result;
                  if (tmp == false) return;
                }
              }
              Navigator.pop(context, _controller.text);
            },
          ),
        ),
      ],
    );
    // 输入框
    Widget input = TextField(
      controller: _controller,
      minLines: 5,
      maxLines: 10,
      maxLength: widget.maxLength,
      buildCounter: (context, {currentLength, isFocused, maxLength}) =>
          Text('$currentLength/$maxLength'),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15.0,
          vertical: 8.0,
        ),
        fillColor: Colors.grey[100],
        filled: true,
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0)),
          borderSide: BorderSide(color: Colors.transparent),
        ),
      ),
    );
    // 结果
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH - 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          top,
          Divider(height: 1.0, thickness: 1.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: input,
            ),
          ),
        ],
      ),
    );
  }
}

/// 选项sheet
class SelectionSheet extends StatelessWidget {
  static Future<int> show(
    BuildContext context, {
    List<String> textSelections,
    List<Widget> widgetSelections,
  }) {
    assert(textSelections?.isNotEmpty == true ||
        widgetSelections?.isNotEmpty == true);
    return showModalBottomSheet<int>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => SelectionSheet(
        textSelections: textSelections,
        widgetSelections: widgetSelections,
      ),
    );
  }

  final List<String> textSelections;
  final List<Widget> widgetSelections;

  SelectionSheet({
    this.textSelections,
    this.widgetSelections,
  });

  @override
  Widget build(BuildContext context) {
    // 选项
    Widget selections;
    if (widgetSelections != null) {
      List<Widget> children = [];
      for (int i = 0; i < widgetSelections.length; i++) {
        children.add(InkWell(
          child: widgetSelections[i],
          onTap: () => Navigator.pop(context, i),
        ));
      }
      selections = ListView(children: children);
    } else if (textSelections != null) {
      List<Widget> children = [];
      for (int i = 0; i < textSelections.length; i++) {
        children.add(
          NormalButton(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            onPressed: () => Navigator.pop(context, i),
            text: textSelections[i],
          ),
        );
      }
      selections = ListView(children: children);
    } else {
      selections = CenterInfoText('没有选项');
    }
    // 结果
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH / 2,
      child: Container(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 取消按钮
            NormalButton(
              text: '取消',
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              onPressed: () => Navigator.of(context).pop(),
            ),
            // 分割线
            Divider(height: 1.0, thickness: 1.0),
            // 选项
            Expanded(child: selections),
          ],
        ),
      ),
    );
  }
}
