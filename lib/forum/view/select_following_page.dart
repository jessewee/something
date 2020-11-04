import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/pub.dart';
import '../../common/view_images.dart';
import '../../common/widgets.dart';

import '../model/m.dart';
import '../repository/repository.dart' as repository;

class SelectFollowingPage extends StatefulWidget {
  static const routeName = 'select_following_page';
  final bool singleSelect;
  const SelectFollowingPage({this.singleSelect = false});
  @override
  _SelectFollowingPageState createState() => _SelectFollowingPageState();
}

class _SelectFollowingPageState extends State<SelectFollowingPage> {
  String _text = '';
  // 搜索次数记录id,cnt
  List<MapEntry<String, int>> _records = [];
  // 接口返回的数据
  List<ForumUser> _data = [];
  // 选中的数据
  List<ForumUser> _selected = [];

  @override
  void initState() {
    SharedPreferences.getInstance().then((sp) {
      _records = sp.getStringList('forum_search_following_page')?.map((e) {
            final tmp = e.split(',');
            return MapEntry(tmp[0], int.parse(tmp[1]));
          }) ??
          [];
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
    final result = await repository.getFollowings(_text);
    if (result.fail) {
      showToast(result.msg);
      return;
    }
    _data = result.data ?? [];
    _data.sort((u0, u1) {
      final c0 = _records
              .firstWhere((e) => e.key == u0.id, orElse: () => null)
              ?.value ??
          0;
      final c1 = _records
              .firstWhere((e) => e.key == u1.id, orElse: () => null)
              ?.value ??
          0;
      return c0.compareTo(c1);
    });
    if (mounted) setState(() {});
  }

  // 数据显示
  Widget _buildContentWidget() {
    if (_text.isEmpty && _data.isEmpty) {
      return Center(child: Text('暂无数据'));
    }
    if (_text.isNotEmpty && _data.isEmpty) {
      return Center(child: Text('没有搜索到数据'));
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
  Widget _buildChip(ForumUser user, bool local) {
    return RawChip(
      label: Text(user.name),
      avatar: ImageWithUrl(
        user.avatarThumb,
        onPressed: () => viewImages(context, [user.avatar]),
      ),
      selected: _selected.contains(user),
      onSelected: (value) {
        if (widget.singleSelect) {
          Navigator.pop(context, user);
          return;
        }
        setState(() {
          if (value && !_selected.contains(user)) {
            _selected.add(user);
          } else if (!value && _selected.contains(user)) {
            _selected.remove(user);
          }
        });
      },
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
                final selectedText = _selected.map((e) => e.name).join(', ');
                final text = Text(
                  '已选择：$selectedText',
                  style: Theme.of(context).textTheme.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
                if (_selected.isEmpty) return text;
                return Tooltip(message: selectedText, child: text);
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
    _records = _selected.map((s) {
      final existed = _records.firstWhere((r) => r.key == s.id);
      if (existed == null) {
        return MapEntry(s.id, 1);
      } else {
        return MapEntry(s.id, existed.value + 1);
      }
    }).toList();
    SharedPreferences.getInstance().then((sp) {
      sp.setStringList(
        'forum_search_following_page',
        _records.map((e) => '${e.key},${e.value}'),
      );
    });
  }
}
