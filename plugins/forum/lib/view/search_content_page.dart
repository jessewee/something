import 'package:flutter/material.dart';
import 'package:forum/model/post.dart';

/// 搜索帖子的SearchDelegate，返回搜索内容，在上一次根据返回的搜索内容调用接口获取帖子列表
/// 这一页主要是显示搜索历史
class SearchPostDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    throw UnimplementedError();
  }

  @override
  Widget buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    throw UnimplementedError();
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    throw UnimplementedError();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    throw UnimplementedError();
  }
}
