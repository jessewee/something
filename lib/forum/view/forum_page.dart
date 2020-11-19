import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/pub.dart';
import '../../common/widgets.dart';
import '../../common/models.dart';
import '../../common/extensions.dart';

import '../repository/repository.dart' as repository;
import 'select_post_label_page.dart';
import 'post_long_content_sheet.dart';
import 'me_page.dart';
import 'posts_page.dart';

/// 社区页
class ForumPage extends StatefulWidget {
  static const routeName = '/forum';

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  int _curTabIdx = 0;
  String _postLabel = '';

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.only(top: top),
        child: IndexedStack(
          index: _curTabIdx,
          children: <Widget>[PostsPage(), MePage()],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: CircularNotchedRectangle(),
        child: BottomNavigationBar(
          currentIndex: _curTabIdx,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              backgroundColor: primaryColor,
              label: '社区',
              icon: Icon(Icons.mode_comment),
            ),
            BottomNavigationBarItem(
              backgroundColor: primaryColor,
              label: '我的',
              icon: Icon(Icons.menu),
            ),
          ],
          onTap: (index) => setState(() => _curTabIdx = index),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!context.checkLogin()) return;
          PostLongContentSheet.show(
            context,
            _onPost,
            label: _LabelWidget((text) => _postLabel = text),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        heroTag: 'forum_page_floating_action_button',
      ),
    );
  }

  // 发帖
  Future<bool> _onPost(String text, List<UploadedFile> medias) async {
    if (_postLabel?.isNotEmpty != true) {
      _postLabel = await _LabelWidget.requireLabel(context);
    }
    if (_postLabel?.isNotEmpty != true) return false;
    final result = await repository.post(
      label: _postLabel,
      content: text,
      mediaIds: medias.map((e) => e.id).toList(),
    );
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    return true;
  }
}

/// 发帖页面的标签按钮
class _LabelWidget extends StatefulWidget {
  final void Function(String) onChange;
  const _LabelWidget(this.onChange);
  @override
  __LabelWidgetState createState() => __LabelWidgetState();

  static Future<String> requireLabel(BuildContext context) async {
    return await _PostLabelSheet.show(context);
  }
}

class __LabelWidgetState extends State<_LabelWidget> {
  String _text = '';
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme.caption;
    if (_text.isEmpty) {
      return TextButton(
        child: Text('标签', style: TextStyle(fontSize: textTheme.fontSize)),
        onPressed: _selectLabel,
      );
    }
    Widget label = NormalButton(
      text: _text,
      backgroundColor: Colors.yellow[900],
      fontSize: textTheme.fontSize,
      onPressed: _selectLabel,
    );
    label = Container(
      margin: const EdgeInsets.only(left: 15.0),
      child: label,
      clipBehavior: Clip.hardEdge,
      decoration: ShapeDecoration(shape: StadiumBorder()),
    );
    label = Tooltip(message: _text, child: label);
    return label;
  }

  void _selectLabel() async {
    final tmp = await _LabelWidget.requireLabel(context);
    if (tmp?.isNotEmpty != true) return;
    _text = tmp;
    widget.onChange(_text);
    setState(() {});
  }
}

/// 发帖时选择标签的页面
class _PostLabelSheet extends StatefulWidget {
  static Future<String> show(BuildContext context) {
    return showModalBottomSheet<String>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(2.0)),
      ),
      context: context,
      builder: (context) => _PostLabelSheet(),
    );
  }

  @override
  __PostLabelSheetState createState() => __PostLabelSheetState();
}

class __PostLabelSheetState extends State<_PostLabelSheet> {
  // 历史记录
  List<String> _records = [];
  StreamController _recordsStreamController;
  // 输入框内容
  String _text = '';
  // 确定按钮状态
  StreamController _controller;

  @override
  void initState() {
    _recordsStreamController = StreamController();
    _controller = StreamController();
    SharedPreferences.getInstance().then((sp) {
      _records = sp.getStringList('forum_post_label_used') ?? [];
      if (_records.length > 0) _recordsStreamController.add(null);
    });
    super.initState();
  }

  @override
  void dispose() {
    _recordsStreamController.makeSureClosed();
    _controller.makeSureClosed();
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
        // 标题
        Text('填写帖子标签'),
        // 确定按钮
        StreamBuilder<Object>(
          initialData: false,
          stream: _controller.stream,
          builder: (context, _) => NormalButton(
            padding: const EdgeInsets.all(15.0),
            text: '确定',
            disabled: _text.isEmpty,
            onPressed: () {
              Navigator.pop(context, _text);
              _saveRecord(_text);
            },
          ),
        ),
      ],
    );
    // 输入框
    Widget input = TextField(
      minLines: 3,
      maxLines: 5,
      maxLength: 20,
      buildCounter: (context, {currentLength, isFocused, maxLength}) =>
          Text('$currentLength/$maxLength'),
      onChanged: (text) {
        if (_text?.isNotEmpty != text?.isNotEmpty) _controller.add(null);
        _text = text;
      },
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
    // 选择按钮
    final select = IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        final result = await Navigator.pushNamed(
          context,
          SelectPostLabelPage.routeName,
          arguments: true,
        );
        if (result == null || result is! String) return;
        Navigator.pop(context, result);
        _saveRecord(result);
      },
    );
    // 历史列表
    Widget records = StreamBuilder(
      stream: _recordsStreamController.stream,
      builder: (context, snapshot) => Visibility(
        visible: _records.isNotEmpty,
        child: Wrap(
          spacing: 5.0,
          children: _records
              .map((e) => ActionChip(
                    label: Text(e),
                    onPressed: () => Navigator.pop(context, e),
                  ))
              .toList(),
        ),
      ),
    );
    // 结果
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH - 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          top,
          Divider(height: 1.0, thickness: 1.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            child: input,
          ),
          select,
          Flexible(child: records),
        ],
      ),
    );
  }

  void _saveRecord(String text) {
    if (_records.contains(text)) return;
    _records.insert(0, text);
    SharedPreferences.getInstance().then((sp) {
      sp.setStringList('forum_post_label_used', _records);
    });
  }
}
