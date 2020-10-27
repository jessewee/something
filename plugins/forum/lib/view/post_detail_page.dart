import 'dart:async';
import 'dart:math';

import 'package:base/base/event_bus.dart';
import 'package:base/base/play_video_page.dart';
import 'package:base/base/pub.dart';
import 'package:base/base/extensions.dart';
import 'package:base/base/view_images.dart';
import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:forum/model/media.dart';
import 'package:forum/model/post.dart';
import 'package:forum/other/iconfont.dart';
import 'package:forum/view/user_page.dart';
import 'package:forum/vm/post_vm.dart';
import 'package:forum/vm/extensions.dart';

import 'post_list_item.dart';

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
    _loading = StreamControllerWithData(null);
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
      body: _buildContent(),
    );
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
            ? _PostItem(widget._vm.post)
            : index < len + 1
                ? _PostFloorItem(widget._vm.floors[index - 1])
                : LoadMore(noMore: widget._vm.noMoreData),
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
      setState(() => _loading.setValueWithoutNotify(null));
    } else {
      showToast(result.msg);
    }
  }
}

/// 第一层，帖子内容
class _PostItem extends StatefulWidget {
  final Post post;

  const _PostItem(this.post);

  @override
  __PostItemState createState() => __PostItemState();
}

class __PostItemState extends State<_PostItem> {
  StreamController<bool> _followStreamController; // 关注按钮改变
  StreamController<int> _likeStreamController; // 点赞按钮改变
  StreamController<int> _dislikeStreamController; // 点踩按钮改变

  @override
  void initState() {
    _followStreamController = StreamController();
    _likeStreamController = StreamController();
    _dislikeStreamController = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _followStreamController.makeSureClosed();
    _likeStreamController.makeSureClosed();
    _dislikeStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 头像
    Widget avatar = ImageWithUrl(
      widget.post.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      onPressed: () => viewImages(context, [widget.post.avatar]),
    );
    // 名字
    Widget name = Text(widget.post.name, style: theme.textTheme.subtitle2);
    // 日期
    Widget date = Text(widget.post.date, style: theme.textTheme.caption);
    // 关注按钮
    Widget follow = StreamBuilder<bool>(
      stream: _followStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.post.posterFollowed
            ? theme.primaryColorLight
            : theme.primaryColor,
        text: widget.post.posterFollowed ? '已关注' : '关注',
        onPressed: _onFollowClick,
      ),
    );
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
        follow,
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      onPressed: _onViewUserClick,
      child: top,
    );
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.post.myAttitude == 1 ? theme.primaryColor : Colors.black,
        icon: Iconfont.like,
        text: '${widget.post.likeCnt}',
        onPressed: _onLikeClick,
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _dislikeStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.post.myAttitude == -1 ? theme.primaryColor : Colors.black,
        icon: Iconfont.dislike,
        text: '${widget.post.dislikeCnt}',
        onPressed: _onDislikeClick,
      ),
    );
    // 点赞、点踩区域
    Widget bottom = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[like, dislike],
    );
    // 文本
    Widget content = Text(widget.post.content);
    // 图片和视频
    Widget media = _buildMedias(context, widget.post.medias);
    // 结果
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        top,
        content.withMargin(left: 8.0, right: 8.0),
        if (media != null) media.withMarginAll(8.0),
        bottom.withMargin(left: 8.0, right: 8.0, bottom: 8.0),
        Divider(color: Colors.grey[100], height: 10.0, thickness: 10.0),
      ],
    );
  }

  // 查看楼主
  void _onViewUserClick() async {
    final result = await Navigator.pushNamed(
      context,
      UserPage.routeName,
      arguments: widget.post.posterId,
    );
    if (result != null && result is bool) {
      widget.post.posterFollowed = result;
      _followStreamController.send(null);
    }
  }

  // 关注按钮
  Future _onFollowClick() async {
    final result = await widget.post.changeFollowPosterStatus();
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _followStreamController.send(null);
    }
    return;
  }

  // 点赞
  Future _onLikeClick() async {
    final target = widget.post.myAttitude == 1 ? null : true;
    final result = await widget.post.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStreamController.send(null);
      eventBus.sendEvent(PostItem.eventBusEventType, {
        'postId': widget.post.id,
        'likeCnt': widget.post.likeCnt,
        'dislikeCnt': widget.post.dislikeCnt,
      });
    }
    return;
  }

  // 点踩
  Future _onDislikeClick() async {
    final target = widget.post.myAttitude == -1 ? null : false;
    final result = await widget.post.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _dislikeStreamController.send(null);
      eventBus.sendEvent(PostItem.eventBusEventType, {
        'postId': widget.post.id,
        'likeCnt': widget.post.likeCnt,
        'dislikeCnt': widget.post.dislikeCnt,
      });
    }
    return;
  }
}

/// 楼层
class _PostFloorItem extends StatefulWidget {
  final Floor floor;

  const _PostFloorItem(this.floor);

  @override
  __PostFloorItemState createState() => __PostFloorItemState();
}

class __PostFloorItemState extends State<_PostFloorItem> {
  StreamController<int> _replyCntStreamController; // 回复按钮改变
  StreamController<int> _likeStreamController; // 点赞按钮改变
  StreamController<int> _dislikeStreamController; // 点踩按钮改变

  @override
  void initState() {
    _replyCntStreamController = StreamController();
    _likeStreamController = StreamController();
    _dislikeStreamController = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _replyCntStreamController.makeSureClosed();
    _likeStreamController.makeSureClosed();
    _dislikeStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftSpace = 60.0; // 下边内容跟名字对齐，所以左边距是头像的宽度加头像的边距
    // 头像
    Widget avatar = ImageWithUrl(
      widget.floor.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      onPressed: () => viewImages(context, [widget.floor.avatar]),
    );
    // 名字
    Widget name = Text(widget.floor.name, style: theme.textTheme.subtitle2);
    // 日期
    Widget date = Text(widget.floor.date, style: theme.textTheme.caption);
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
        arguments: widget.floor.posterId,
      ),
    );
    // 文本
    Widget content = Text(widget.floor.content);
    // 图片和视频
    Widget media = _buildMedias(context, widget.floor.medias);
    // 查看回复
    Widget viewReplies;
    if (widget.floor.replyCnt > 0) {
      viewReplies = StreamBuilder<int>(
          stream: _replyCntStreamController.stream,
          builder: (context, _) {
            return TextButton(
              child: Text(
                '查看${widget.floor.replyCnt}条回复>>',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.normal,
                ),
              ),
              onPressed: _viewReplies,
            );
          });
    }
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.floor.myAttitude == 1 ? theme.primaryColor : Colors.black,
        icon: Iconfont.like,
        text: '${widget.floor.likeCnt}',
        onPressed: _onLikeClick,
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _dislikeStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color:
            widget.floor.myAttitude == -1 ? theme.primaryColor : Colors.black,
        icon: Iconfont.dislike,
        text: '${widget.floor.dislikeCnt}',
        onPressed: _onDislikeClick,
      ),
    );
    // 点赞、点踩、查看回复区域
    Widget buttons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (viewReplies != null) Expanded(child: viewReplies),
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

  // 查看回复
  void _viewReplies() async {
    // TODO
    final result = await showDialog(context: null);
    if (result != null && result is int) {
      widget.floor.replyCnt = result;
      _replyCntStreamController.send(null);
    }
  }

  // 点赞
  Future _onLikeClick() async {
    final target = widget.floor.myAttitude == 1 ? null : true;
    final result = await widget.floor.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStreamController.send(null);
    }
    return;
  }

  // 点踩
  Future _onDislikeClick() async {
    final target = widget.floor.myAttitude == -1 ? null : false;
    final result = await widget.floor.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _dislikeStreamController.send(null);
    }
    return;
  }
}

// 图片和视频显示
Widget _buildMedias(BuildContext context, List<Media> medias) {
  if (medias.isEmpty) return null;
  final list = <Widget>[];
  for (final m in medias) {
    if (m is ImageMedia) {
      list.add(AspectRatio(
        aspectRatio: m.width / m.height,
        child: ImageWithUrl(
          m.thumbUrl,
          fit: BoxFit.cover,
          onPressed: () => _viewMediaImages(context, m, medias),
        ),
      ));
    } else if (m is VideoMedia) {
      list.add(AspectRatio(
        aspectRatio: 1.75,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ImageWithUrl(m.coverUrl, fit: BoxFit.cover).positioned(),
            IconButton(
              icon: Icon(Icons.play_circle_outline),
              color: Colors.white,
              iconSize: 50.0,
              onPressed: () => playVideo(context, m.url),
            ),
          ],
        ),
      ));
    }
  }
  if (list.isEmpty) return null;
  return Column(
    children: list,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
  );
}

// 查看图片
void _viewMediaImages(
  BuildContext context,
  ImageMedia cur,
  List<Media> medias,
) {
  final images = medias.whereType<ImageMedia>().toList();
  final idx = images.indexOf(cur);
  viewImages(context, images.map((e) => e.url).toList(), max(0, idx));
}
