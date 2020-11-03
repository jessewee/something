import 'dart:async';

import 'package:base/base/extensions.dart';
import 'package:base/base/pub.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forum/model/post.dart';
import 'package:forum/view/post_base_item_content.dart';
import 'package:forum/vm/floor_vm.dart';

import 'bottom_reply_bar.dart';

/// 楼层回复列表页面，这个用showModalBottomSheet显示，不注册在页面路由里
class PostFloorRepliesPage extends StatefulWidget {
  final FloorVM _vm;

  PostFloorRepliesPage(Floor floor) : _vm = FloorVM(floor);

  @override
  _PostFloorRepliesPageState createState() => _PostFloorRepliesPageState();
}

class _PostFloorRepliesPageState extends State<PostFloorRepliesPage> {
  StreamControllerWithData<InnerFloor> _replyTarget;
  ScrollController _scrollController;
  bool _loading; // true:刷新、false:加载更多、null:不在加载状态

  @override
  void initState() {
    _replyTarget = StreamControllerWithData(null);
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (_loading != null) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 50) {
        _loadData(refresh: false);
      }
    });
    _loading = true; // 为了底部的LoadingMore不显示没有更多数据了
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData());
    super.initState();
  }

  @override
  void dispose() {
    _replyTarget.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final titlePart = widget._vm.totalCnt > 0 ? '${widget._vm.totalCnt}条' : '';
    final len = widget._vm.innerFloors.length;
    return Container(
      height: screenH - 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 60.0,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Text('${widget._vm.floor.floor}楼的$titlePart回复'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, widget._vm.totalCnt),
                ).positioned(right: null),
                Divider(height: 1.0, thickness: 1.0).positioned(top: null),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: len + 1,
              itemBuilder: (context, index) => index < len
                  ? PostBaseItemContent(
                      widget._vm.innerFloors[index],
                      () => _replyTarget.add(widget._vm.innerFloors[index]),
                    )
                  : LoadMore(noMore: _loading == null && widget._vm.noMoreData),
            ),
          ),
          StreamBuilder<PostBase>(
              initialData: _replyTarget.value,
              stream: _replyTarget.stream,
              builder: (context, snapshot) {
                if (snapshot.data == null) {
                  return BottomReplyBar(
                    floorId: widget._vm.floor.id,
                    onReplied: _onReplied,
                  );
                } else if (snapshot.data is InnerFloor) {
                  String targetId, targetName;
                  if (snapshot.data.posterId == widget._vm.floor.posterId) {
                    // 回复层主时不显示目标名字
                    targetId = '';
                    targetName = '';
                  } else {
                    targetId = snapshot.data.posterId;
                    targetName = snapshot.data.name;
                  }
                  return BottomReplyBar(
                    innerFloorId: snapshot.data.id,
                    targetId: targetId,
                    targetName: targetName,
                    onReplied: _onReplied,
                  );
                } else {
                  return Container();
                }
              }),
        ],
      ),
    );
  }

  // 加载数据
  Future _loadData({bool refresh = true}) async {
    _loading = refresh;
    final result = await widget._vm.getInnerFloors(refresh: refresh);
    if (result.success) {
      setState(() {});
    } else {
      showToast(result.msg);
    }
    _loading = null;
  }

  // 回复发送成功的回调
  void _onReplied(PostBase postBase) {
    // TODO
    if (postBase is Post) {}
  }
}
