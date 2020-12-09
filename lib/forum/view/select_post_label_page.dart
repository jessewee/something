import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/pub.dart';
import '../../common/widgets.dart';

import '../repository/repository.dart' as repository;

/// 选择标签给上一页，可多选
class SelectPostLabelPage extends StatefulWidget {
  static const routeName = 'forum_select_post_label_page';
  final bool singleSelect;
  const SelectPostLabelPage({this.singleSelect = false});
  @override
  _SelectPostLabelState createState() => _SelectPostLabelState();
}

class _SelectPostLabelState extends State<SelectPostLabelPage> {
  String _text = '';

  // 搜索历史记录
  List<String> _records = [];
  // 接口返回的数据
  List<String> _data = [];
  // 选中的数据
  List<String> _selected = [];

  @override
  void initState() {
    SharedPreferences.getInstance().then((sp) {
      _records = sp.getStringList('forum_search_post_label_page') ?? [];
      if (mounted) setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(onConfirm: _onSearch),
      body: widget.singleSelect
          ? _buildContentWidget()
          : Container(
              padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildContentWidget()),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.black38)),
                    ),
                    child: _buildBottomWidget(),
                  ),
                ],
              ),
            ),
    );
  }

  // 搜索数据
  Future<void> _onSearch(String text) async {
    _text = text;
    if (_text.isEmpty) {
      setState(() {});
      return;
    }
    final result = await repository.getPostLabels(_text);
    if (result.fail) {
      showToast(result.msg);
      return;
    }
    _data = result.data ?? [];
    if (mounted) setState(() {});
  }

  // 数据显示
  Widget _buildContentWidget() {
    if (_text.isEmpty && _records.isEmpty) {
      return Center(child: Text('暂无历史记录'));
    }
    if (_text.isNotEmpty && _data.isEmpty) {
      return Center(child: Text('暂无数据'));
    }
    if (_text.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          spacing: 5.0,
          children: _records.map((e) => _buildChip(e, true)).toList(),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Wrap(
        spacing: 5.0,
        children: _data.map((e) => _buildChip(e, false)).toList(),
      ),
    );
  }

  // 选项Widget
  Widget _buildChip(String text, bool local) {
    return RawChip(
      label: Text(text),
      selected: _selected.contains(text),
      onSelected: (value) {
        if (widget.singleSelect) {
          Navigator.pop(context, text);
          return;
        }
        setState(() {
          if (value && !_selected.contains(text)) {
            _selected.add(text);
          } else if (!value && _selected.contains(text)) {
            _selected.remove(text);
          }
        });
      },
      deleteIcon: Icon(Icons.delete, color: Colors.red),
      onDeleted: local
          ? () => setState(() {
                _records.remove(text);
                SharedPreferences.getInstance().then((sp) {
                  sp.setStringList('forum_search_post_label_page', _records);
                });
              })
          : null,
    );
  }

  // 底部按纽栏
  Widget _buildBottomWidget() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(left: 8.0),
            child: Builder(
              builder: (_) {
                final text = Text(
                  '已选择：${_selected.join(', ')}',
                  style: Theme.of(context).textTheme.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                if (_selected.isEmpty) return text;
                return Tooltip(message: _selected.join(', '), child: text);
              },
            ),
          ),
        ),
        TextButton(child: Text('确定'), onPressed: _onConfirm),
      ],
    );
  }

  // 确定返回结果
  void _onConfirm() {
    Navigator.pop(context, _selected);
    final tmp = _selected.where((s) => !_records.contains(s));
    if (tmp.isEmpty) return;
    _records.addAll(tmp);
    SharedPreferences.getInstance().then((sp) {
      sp.setStringList('forum_search_post_label_page', _records);
    });
  }
}
