import 'package:flutter/material.dart';

import '../../common/pub.dart';
import '../../common/widgets.dart';

import '../model/post.dart';
import 'post_list_item.dart';

class PostList extends StatefulWidget {
  final List<Post> posts;
  final bool loading; // true: 刷新、false: 下一页、null: 不在加载状态中
  final bool noMoreData;
  final String errorMsg;
  final Future Function(bool) loadData;

  const PostList({
    this.posts = const [],
    this.loading = false,
    this.noMoreData = false,
    this.errorMsg = '',
    this.loadData,
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
      if (pos.pixels >= pos.maxScrollExtent - LoadMore.validHeight) {
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
            : PostItem(widget.posts[index]),
      );
    }
    return RefreshIndicator(
      onRefresh: () => widget.loadData(true),
      child: child,
    );
  }
}
