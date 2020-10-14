import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 返回搜索内容，在上一页根据返回的搜索内容调用接口获取帖子列表
/// 这一页主要是显示搜索历史
class SearchContentPage extends StatefulWidget {
  static const routeName = 'search_content_page';

  @override
  _SearchContentPageState createState() => _SearchContentPageState();
}

class _SearchContentPageState extends State<SearchContentPage> {
  List<String> records = [];

  @override
  void initState() {
    SharedPreferences.getInstance().then((sp) {
      setState(() {
        records = sp.getStringList('forum_search_content_page') ?? [];
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final searchTextStyle = Theme.of(context).textTheme.bodyText2;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        title: Container(
          height: 40.0,
          margin: const EdgeInsets.only(right: 15.0),
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
              hintText: '请输入搜索内容',
              hintStyle: searchTextStyle.copyWith(color: Colors.grey),
            ),
            style: searchTextStyle,
            onSubmitted: (text) {
              Navigator.pop(context, text);
              if (records.contains(text)) return;
              records.add(text);
              SharedPreferences.getInstance().then((sp) {
                sp.setStringList('forum_search_content_page', records);
              });
            },
          ),
        ),
      ),
      body: records.isEmpty
          ? Center(child: Text('暂无搜索记录'))
          : Container(
              padding: const EdgeInsets.all(12.0),
              child: Wrap(
                spacing: 5.0,
                children: records.map((e) => _buildChip(e)).toList(),
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
        records.remove(text);
        SharedPreferences.getInstance().then((sp) {
          sp.setStringList('forum_search_content_page', records);
        });
      }),
    );
  }
}
