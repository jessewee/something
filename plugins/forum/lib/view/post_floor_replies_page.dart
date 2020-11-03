import 'dart:async';

import 'package:base/base/pub.dart';
import 'package:base/base/view_images.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forum/model/post.dart';
import 'package:base/base/extensions.dart';
import 'package:forum/other/iconfont.dart';
import 'package:forum/view/user_page.dart';
import 'package:forum/vm/extensions.dart';
import 'package:forum/vm/floor_vm.dart';
import 'bottom_reply_bar.dart';
import 'post_detail_page.dart';

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
                ).positioned(left: null),
                Divider(height: 1.0, thickness: 1.0).positioned(top: null),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: len + 1,
              itemBuilder: (context, index) => index < len
                  ? _PostInnerFloorItem(
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

/// 楼层内回复
class _PostInnerFloorItem extends StatefulWidget {
  final InnerFloor innerFloor;
  final Function() onReplyClick;

  const _PostInnerFloorItem(this.innerFloor, this.onReplyClick);

  @override
  ___PostInnerFloorItemState createState() => ___PostInnerFloorItemState();
}

class ___PostInnerFloorItemState extends State<_PostInnerFloorItem> {
  StreamController<int> _likeStatusStreamController; // 点赞点踩按钮改变

  @override
  void initState() {
    _likeStatusStreamController = StreamController.broadcast();
    super.initState();
  }

  @override
  void dispose() {
    _likeStatusStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftSpace = 60.0; // 下边内容跟名字对齐，所以左边距是头像的宽度加头像的边距
    // 头像
    Widget avatar = ImageWithUrl(
      widget.innerFloor.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      onPressed: () => viewImages(context, [widget.innerFloor.avatar]),
    );
    // 名字
    Widget name =
        Text(widget.innerFloor.name, style: theme.textTheme.subtitle2);
    // 日期
    Widget date = Text(widget.innerFloor.date, style: theme.textTheme.caption);
    // 头像、名字、日期区域
    Widget top = Row(
      children: <Widget>[
        avatar.withMargin(right: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[name, date.withMargin(top: 8.0)],
          ),
        ),
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: top,
      onPressed: () => Navigator.pushNamed(
        context,
        UserPage.routeName,
        arguments: widget.innerFloor.posterId,
      ),
    );
    // 文本
    Widget content = Text(widget.innerFloor.content);
    // 图片和视频
    Widget media = buildMedias(context, widget.innerFloor.medias);
    // 回复
    Widget viewReplies = TextButton(
      child: Text(
        '回复',
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.normal,
        ),
      ),
      onPressed: widget.onReplyClick,
    );
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.innerFloor.myAttitude == 1
            ? theme.primaryColor
            : Colors.black,
        icon: Iconfont.like,
        text: '${widget.innerFloor.likeCnt}',
        onPressed: _onLikeClick,
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.innerFloor.myAttitude == -1
            ? theme.primaryColor
            : Colors.black,
        icon: Iconfont.dislike,
        text: '${widget.innerFloor.dislikeCnt}',
        onPressed: _onDislikeClick,
      ),
    );
    // 点赞、点踩、查看回复区域
    Widget buttons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(child: viewReplies),
        like,
        dislike,
      ],
    );
    // 头像名字日期之下的部分
    Widget bottom = Container(
      padding: const EdgeInsets.only(left: leftSpace, right: 12.0),
      child: Column(
        children: [
          content,
          if (media != null) media.withMargin(top: 8.0),
          buttons.withMargin(top: 8.0),
          Divider(color: Colors.grey[300], height: 1.0).withMargin(top: 8.0),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[top, bottom],
    );
  }

  // 点赞
  Future _onLikeClick() async {
    final target = widget.innerFloor.myAttitude == 1 ? null : true;
    final result = await widget.innerFloor.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStatusStreamController.send(null);
    }
    return;
  }

  // 点踩
  Future _onDislikeClick() async {
    final target = widget.innerFloor.myAttitude == -1 ? null : false;
    final result = await widget.innerFloor.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStatusStreamController.send(null);
    }
    return;
  }
}
