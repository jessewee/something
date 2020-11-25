import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../common/extensions.dart';
import '../../common/pub.dart';
import '../../common/widgets.dart';

import '../vm/reply_vm.dart';
import '../model/post.dart';
import 'bottom_reply_bar.dart';
import 'post_base_item_content.dart';
import '../vm/floor_vm.dart';
import 'post_long_content_sheet.dart';

/// 楼层回复列表页面，这个用showModalBottomSheet显示，不注册在页面路由里
class PostFloorRepliesSheet extends StatefulWidget {
  static Future show(BuildContext context, Floor floor) {
    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(2.0),
        ),
      ),
      context: context,
      builder: (context) => PostFloorRepliesSheet(floor),
    );
  }

  final Floor floor;
  PostFloorRepliesSheet(this.floor);

  @override
  _PostFloorRepliesSheetState createState() => _PostFloorRepliesSheetState();
}

class _PostFloorRepliesSheetState extends State<PostFloorRepliesSheet> {
  ScrollController _scrollController;
  bool _loading; // true:刷新、false:加载更多、null:不在加载状态
  FloorVM _vm;

  @override
  void initState() {
    _vm = FloorVM(widget.floor);
    _scrollController = ScrollController();
    _scrollController.addListener(() async {
      if (_loading != null) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - LoadMore.validHeight) {
        _loadData(refresh: false);
      }
    });
    _loading = true; // 为了底部的LoadingMore不显示没有更多数据了
    SchedulerBinding.instance.addPostFrameCallback((_) => _loadData());
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenH = mediaQuery.size.height;
    final bottom = mediaQuery.viewInsets.bottom;
    final titlePart = _vm.totalCnt > 0 ? '${_vm.totalCnt}条' : '';
    final len = _vm.innerFloors.length;
    return Container(
      height: screenH - 60 - bottom,
      margin: EdgeInsets.only(bottom: bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 60.0,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // ignore: unnecessary_brace_in_string_interps
                Text('${_vm.floor.floor}楼的${titlePart}回复'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _vm.totalCnt),
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
                      _vm.innerFloors[index],
                      () {
                        final innerFloor = _vm.innerFloors[index];
                        PostLongContentSheet.show(
                            context,
                            ReplyVM(
                              postId: _vm.floor.postId,
                              floorId: _vm.floor.id,
                              innerFloorId: innerFloor.id,
                              targetId: innerFloor.posterId ?? '',
                              targetName: innerFloor.name ?? '',
                              onReplied: _onReplied,
                            ));
                      },
                    )
                  : LoadMore(noMore: _loading == null && _vm.noMoreData),
            ),
          ),
          BottomReplyBar(ReplyVM(
            postId: _vm.floor.postId,
            floorId: _vm.floor.id,
            onReplied: _onReplied,
          )),
        ],
      ),
    );
  }

  // 加载数据
  Future _loadData({bool refresh = true}) async {
    _loading = refresh;
    final result = await _vm.getInnerFloors(refresh: refresh);
    _loading = null;
    if (result.success) {
      setState(() {});
    } else {
      showToast(result.msg);
    }
  }

  // 回复发送成功的回调
  void _onReplied(PostBase postBase) {
    setState(() => _vm.addNewReply(postBase as InnerFloor));
  }
}
