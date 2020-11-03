import 'dart:async';

import 'package:base/base/widgets.dart';
import 'package:flutter/material.dart';
import 'package:forum/model/post.dart';
import 'package:base/base/extensions.dart';
import 'package:base/base/pub.dart';
import 'package:base/base/view_images.dart';
import 'package:forum/other/iconfont.dart';
import 'package:forum/view/user_page.dart';
import 'package:forum/vm/extensions.dart';
import 'post_detail_page.dart';

/// 帖子里的楼层和层内的内容
class PostBaseItemContent extends StatefulWidget {
  final PostBase postBase;
  final Function() onReplyClick;

  const PostBaseItemContent(this.postBase, this.onReplyClick);

  @override
  _PostBaseItemContentState createState() => _PostBaseItemContentState();
}

class _PostBaseItemContentState extends State<PostBaseItemContent> {
  StreamController<int> _likeStatusStreamController; // 点赞点踩按钮改变
  StreamController<bool> _followStreamController; // 关注按钮改变

  @override
  void initState() {
    _likeStatusStreamController = StreamController.broadcast();
    if (widget.postBase is Post) {
      _followStreamController = StreamController();
    }
    super.initState();
  }

  @override
  void dispose() {
    _followStreamController?.makeSureClosed();
    _likeStatusStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const leftSpace = 60.0; // 下边内容跟名字对齐，所以左边距是头像的宽度加头像的边距
    // 头像
    Widget avatar = ImageWithUrl(
      widget.postBase.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      onPressed: () => viewImages(context, [widget.postBase.avatar]),
    );
    // 名字
    Widget name = Text(widget.postBase.name, style: theme.textTheme.subtitle2);
    // 日期
    Widget date = Text(widget.postBase.date, style: theme.textTheme.caption);
    // 关注按钮
    Widget follow;
    if (widget.postBase is Post) {
      final post = widget.postBase as Post;
      follow = StreamBuilder<bool>(
        stream: _followStreamController.stream,
        builder: (context, _) => ButtonWithIcon(
          color: post.posterFollowed
              ? theme.primaryColorLight
              : theme.primaryColor,
          text: post.posterFollowed ? '已关注' : '关注',
          onPressed: _onFollowClick,
        ),
      );
    }
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
        if (follow != null) follow,
      ],
    );
    top = FlatButton(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: top,
      onPressed: _onViewUserClick,
    );
    // 文本
    Widget content = Text(widget.postBase.content);
    // 图片和视频
    Widget media = buildMedias(context, widget.postBase.medias);
    // 回复
    Widget viewReplies;
    if (widget.postBase is! Post) {
      var replyText = '';
      if (widget.postBase is InnerFloor) {
        replyText = '回复';
      } else if (widget.postBase is Floor) {
        final floor = widget.postBase as Floor;
        replyText = floor.replyCnt > 0 ? '查看${floor.replyCnt}条回复>>' : '回复';
      }
      viewReplies = TextButton(
        child: Text(
          replyText,
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.normal,
          ),
        ),
        onPressed: widget.onReplyClick,
      );
    }
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color:
            widget.postBase.myAttitude == 1 ? theme.primaryColor : Colors.black,
        icon: Iconfont.like,
        text: '${widget.postBase.likeCnt}',
        onPressed: _onLikeClick,
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => ButtonWithIcon(
        color: widget.postBase.myAttitude == -1
            ? theme.primaryColor
            : Colors.black,
        icon: Iconfont.dislike,
        text: '${widget.postBase.dislikeCnt}',
        onPressed: _onDislikeClick,
      ),
    );
    // 点赞、点踩、查看回复区域
    Widget buttons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        viewReplies == null ? Spacer() : Expanded(child: viewReplies),
        like,
        dislike,
      ],
    );
    // 头像名字日期之下的部分
    Widget bottom = Column(
      children: [
        content,
        if (media != null) media.withMargin(top: 8.0),
        buttons.withMargin(top: 8.0),
        Divider(color: Colors.grey[300], height: 1.0).withMargin(top: 8.0),
      ],
    );
    if (widget.postBase is! Post) {
      bottom = Container(
        padding: const EdgeInsets.only(left: leftSpace, right: 12.0),
        child: bottom,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[top, bottom],
    );
  }

  // 点赞
  Future _onLikeClick() async {
    final target = widget.postBase.myAttitude == 1 ? null : true;
    final result = await widget.postBase.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStatusStreamController.send(null);
    }
    return;
  }

  // 点踩
  Future _onDislikeClick() async {
    final target = widget.postBase.myAttitude == -1 ? null : false;
    final result = await widget.postBase.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStatusStreamController.send(null);
    }
    return;
  }

  // 查看发布人
  void _onViewUserClick() async {
    final result = await Navigator.pushNamed(
      context,
      UserPage.routeName,
      arguments: widget.postBase.posterId,
    );
    if (widget.postBase is Post && result != null && result is bool) {
      (widget.postBase as Post).posterFollowed = result;
      _followStreamController?.send(null);
    }
  }

  // 关注按钮
  Future _onFollowClick() async {
    final post = widget.postBase as Post;
    final result = await post.changeFollowPosterStatus();
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _followStreamController.send(null);
    }
    return;
  }
}
