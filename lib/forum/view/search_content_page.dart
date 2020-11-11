import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/widgets.dart';

/// 返回搜索内容，在上一页根据返回的搜索内容调用接口获取帖子列表
/// 这一页主要是显示搜索历史
class SearchContentPage extends StatefulWidget {
  static const routeName = '/forum/search_content_page';

  @override
  _SearchContentPageState createState() => _SearchContentPageState();
}

class _SearchContentPageState extends State<SearchContentPage> {
  List<String> _records = [];

  @override
  void initState() {
    SharedPreferences.getInstance().then((sp) {
      if (mounted)
        setState(() {
          _records = sp.getStringList('forum_search_content_page') ?? [];
        });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(onConfirm: _onConfirm),
      body: _records.isEmpty
          ? Center(child: Text('暂无搜索记录'))
          : Container(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 5.0,
                children: _records.map((e) => _buildChip(e)).toList(),
              ),
            ),
    );
  }

  Widget _buildChip(String text) {
    return RawChip(
      label: Text(text),
      onPressed: () => Navigator.pop(context, text),
      deleteIcon: Icon(Icons.delete, color: Colors.red),
      onDeleted: () => setState(() {
        _records.remove(text);
        SharedPreferences.getInstance().then((sp) {
          sp.setStringList('forum_search_content_page', _records);
        });
      }),
    );
  }

  Future<void> _onConfirm(String text) async {
    Navigator.pop(context, text);
    if (text.isEmpty || _records.contains(text)) return;
    _records.add(text);
    SharedPreferences.getInstance().then((sp) {
      sp.setStringList('forum_search_content_page', _records);
    });
    return;
  }
}
