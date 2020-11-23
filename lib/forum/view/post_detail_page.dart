import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../common/pub.dart';
import '../../common/widgets.dart';

import '../model/post.dart';
import '../view/bottom_reply_bar.dart';
import '../view/post_base_item_content.dart';
import '../vm/post_vm.dart';

/// 帖子详情
class PostDetailPage extends StatefulWidget {
  static const routeName = '/forum/post_detail';
  final Post post;

  PostDetailPage(this.post);

  @override
  _PostDetailPageState createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  StreamControllerWithData<bool> _loading; // true: 刷新、false: 下一页、null: 不在加载状态中
  ScrollController _scrollController;
  PostVM _vm;

  @override
  void initState() {
    _vm = PostVM(widget.post);
    _loading = StreamControllerWithData(null, broadcast: true);
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (_loading.value == false) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - LoadMore.validHeight) {
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
            stream: _loading.stream,
            builder: (context, snapshot) {
              return TextWithLoading(_vm.post.label, _loading.value != null);
            }),
        actions: [
          if (_vm.totalFloorCnt > 200)
            TextButton(child: Text('跳转楼层'), onPressed: _showToFloors),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildContent()),
          BottomReplyBar(ReplyVM(postId: _vm.post.id, onReplied: _onReplied)),
        ],
      ),
    );
  }

  // 回复发送成功的回调
  void _onReplied(PostBase postBase) {
    setState(() => _vm.addNewReply(postBase as Floor));
  }

  // 内容显示
  Widget _buildContent() {
    final len = _vm.floors.length;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: len + 2,
        itemBuilder: (context, index) => index == 0
            ? PostBaseItemContent(_vm.post)
            : index < len + 1
                ? PostBaseItemContent(_vm.floors[index - 1])
                : StreamBuilder<bool>(
                    stream: _loading.stream,
                    builder: (context, snapshot) {
                      return LoadMore(
                        noMore: _loading.value == null && _vm.noMoreData,
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
        var cnt = _vm.totalFloorCnt ~/ pageSize;
        var remain = _vm.totalFloorCnt % pageSize;
        if (remain >= pageSize / 2) cnt++;
        final items = <MapEntry<String, void Function()>>[];
        for (var i = 0; i < cnt; i++) {
          final start = pageSize * i + 1;
          final end =
              i == cnt - 1 ? _vm.totalFloorCnt : (pageSize * (i + 1) + 1);
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
    final result = await _vm.getFloors(
      refresh: refresh,
      dataSize: 100,
      floorStartIdx: floorStartIdx,
      floorEndIdx: floorEndIdx,
    );
    if (result.success) {
      if (mounted) setState(() => _loading.setValueWithoutNotify(null));
    } else {
      _loading.add(null);
      showToast(result.msg);
    }
  }
}
