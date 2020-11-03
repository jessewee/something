import 'dart:async';

import 'package:base/base/pub.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forum/model/post.dart';
import 'package:forum/view/bottom_reply_bar.dart';
import 'package:forum/view/post_base_item_content.dart';
import 'package:forum/vm/post_vm.dart';

/// 帖子详情
class PostDetailPage extends StatefulWidget {
  static const routeName = '/forum/post_detail';
  final PostVM _vm;

  PostDetailPage(Post post) : _vm = PostVM(post);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  StreamControllerWithData<bool> _loading; // true: 刷新、false: 下一页、null: 不在加载状态中
  ScrollController _scrollController;

  @override
  void initState() {
    _loading = StreamControllerWithData(null, broadcast: true);
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (_loading.value == false) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 50) {
        _loadData(refresh: false);
      }
    });
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData());
    super.initState();
  }

  @override
  void dispose() {
    _loading.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<bool>(
            initialData: _loading.value,
            stream: _loading.stream,
            builder: (context, snapshot) {
              return TextWithLoading(
                widget._vm.post.label,
                snapshot.data != null,
              );
            }),
        actions: [
          if (widget._vm.totalFloorCnt > 200)
            TextButton(child: Text('跳转楼层'), onPressed: _showToFloors),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          BottomReplyBar(postId: widget._vm.post.id, onReplied: _onReplied),
        ],
      ),
    );
  }

  // 回复发送成功的回调
  void _onReplied(PostBase postBase) {
    setState(() => widget._vm.addNewReply(postBase));
  }

  // 内容显示
  Widget _buildContent() {
    final len = widget._vm.floors.length;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: len + 2,
        itemBuilder: (context, index) => index == 0
            ? PostBaseItemContent(widget._vm.post)
            : index < len + 1
                ? PostBaseItemContent(widget._vm.floors[index - 1])
                : StreamBuilder<bool>(
                    stream: _loading.stream,
                    builder: (context, snapshot) {
                      return LoadMore(
                        noMore: snapshot.data == null && widget._vm.noMoreData,
                      );
                    }),
      ),
    );
  }

  // 显示跳转楼层弹出框
  void _showToFloors() {
    showDialog(
      context: context,
      builder: (context) {
        const pageSize = 100;
        var cnt = widget._vm.totalFloorCnt ~/ pageSize;
        var remain = widget._vm.totalFloorCnt % pageSize;
        if (remain >= pageSize / 2) cnt++;
        final items = <MapEntry<String, void Function()>>[];
        for (var i = 0; i < cnt; i++) {
          final start = pageSize * i + 1;
          final end = i == cnt - 1
              ? widget._vm.totalFloorCnt
              : (pageSize * (i + 1) + 1);
          items.add(MapEntry(
            '$start楼~$end楼',
            () => _loadData(floorStartIdx: start, floorEndIdx: end),
          ));
        }
        return ListView(
          children: items
              .map((e) => TextButton(
                    child: Text(e.key),
                    onPressed: () {
                      Navigator.pop(context);
                      e.value.call();
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  // 加载数据
  Future _loadData({
    bool refresh = true,
    int floorStartIdx,
    int floorEndIdx,
  }) async {
    _loading.add(refresh);
    final result = await widget._vm.getFloors(
      refresh: refresh,
      dataSize: 100,
      floorStartIdx: floorStartIdx,
      floorEndIdx: floorEndIdx,
    );
    _loading.add(null);
    if (result.success) {
      if (mounted) setState(() => _loading.setValueWithoutNotify(null));
    } else {
      showToast(result.msg);
    }
  }
}
