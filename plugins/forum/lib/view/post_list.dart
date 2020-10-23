import 'package:base/base/pub.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forum/model/post.dart';

import 'post_list_item.dart';

class PostList extends StatefulWidget {
  final List<Post> posts;
  final bool loading; // true: 刷新、false: 下一页、null: 不在加载状态中
  final bool noMoreData;
  final String errorMsg;
  final void Function(bool) loadData;
  final void Function(String, PostClickType, [dynamic]) onPostClick;
  const PostList({
    this.posts = const [],
    this.loading = false,
    this.noMoreData = false,
    this.errorMsg = '',
    this.loadData,
    this.onPostClick,
  });

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  ScrollController _scrollController;
  bool loadingMore = false;

  @override
  void initState() {
    loadingMore = widget.loading == false;
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (widget.loading != null || loadingMore || widget.noMoreData) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 50) {
        loadingMore = true;
        widget.loadData(false);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading != false) loadingMore = false;
    if (widget.posts.isNotEmpty && widget.errorMsg.isNotEmpty)
      showToast(widget.errorMsg);
    final len = widget.posts.length;
    Widget child;
    if (widget.posts.isEmpty) {
      if (widget.errorMsg.isNotEmpty) {
        child = CenterInfoText(widget.errorMsg);
      } else if (widget.loading != null) {
        child = CenterInfoText('加载中...');
      } else {
        child = CenterInfoText('暂无数据');
      }
    } else {
      child = ListView.builder(
        controller: _scrollController,
        itemCount: len + 1,
        itemBuilder: (context, index) => index == len
            ? LoadMore(noMore: widget.noMoreData)
            : PostItem(widget.posts[index], widget.onPostClick),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => widget.loadData(true),
      child: child,
    );
  }
}
