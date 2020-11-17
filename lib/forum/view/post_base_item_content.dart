import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/models.dart';
import '../../common/play_video_page.dart';
import '../../common/widgets.dart';
import '../../common/extensions.dart';
import '../../common/pub.dart';
import '../../common/view_images.dart';

import '../model/post.dart';
import '../../base/iconfont.dart';
import 'post_floor_replies_sheet.dart';
import '../view/user_page.dart';
import '../vm/extensions.dart';

/// 帖子里的楼层和层内的内容
class PostBaseItemContent extends StatefulWidget {
  final PostBase postBase;
  final Function() onReplyClick;

  const PostBaseItemContent(this.postBase, [this.onReplyClick]);

  @override
  _PostBaseItemContentState createState() => _PostBaseItemContentState();
}

class _PostBaseItemContentState extends State<PostBaseItemContent> {
  StreamController<int> _likeStatusStreamController; // 点赞点踩按钮改变
  StreamController<bool> _followStreamController; // 关注按钮改变
  StreamController<int> _replyCntStreamController; // 回复按钮改变

  @override
  void initState() {
    _likeStatusStreamController = StreamController.broadcast();
    if (widget.postBase is Post) {
      _followStreamController = StreamController();
    } else if (widget.postBase is Floor) {
      _replyCntStreamController = StreamController();
    }
    super.initState();
  }

  @override
  void dispose() {
    _replyCntStreamController?.makeSureClosed();
    _followStreamController?.makeSureClosed();
    _likeStatusStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 头像
    Widget avatar = ImageWithUrl(
      widget.postBase.avatarThumb,
      round: true,
      width: 50.0,
      height: 50.0,
      backgroundColor: Colors.grey[200],
      errorWidget: Icon(Icons.emoji_people),
      onPressed: () => viewImages(context, [widget.postBase.avatar]),
    );
    // 名字
    Widget name = Text(widget.postBase.name, style: theme.textTheme.subtitle2);
    // 日期
    Widget date = Text(widget.postBase.date, style: theme.textTheme.caption);
    // 标签
    Widget label;
    if (widget.postBase is Post) {
      final post = widget.postBase as Post;
      label = Text(
        post.label,
        style: theme.textTheme.caption.copyWith(color: Colors.white),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
      label = Container(
        child: label,
        padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
        decoration: ShapeDecoration(
          color: Colors.yellow[900],
          shape: StadiumBorder(),
        ),
      );
      label = Tooltip(message: post.label, child: label);
    }
    // 关注按钮
    Widget follow;
    if (widget.postBase is Post) {
      final post = widget.postBase as Post;
      follow = StreamBuilder<bool>(
        stream: _followStreamController.stream,
        builder: (context, _) => NormalButton(
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
            children: <Widget>[
              name,
              label == null
                  ? date.withMargin(top: 8.0)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        date.withMargin(right: 8.0),
                        Flexible(child: label),
                      ],
                    ).withMargin(top: 8.0),
            ],
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
    Widget media = _buildMedias(context, widget.postBase.medias);
    // 回复
    Widget viewReplies;
    if (widget.postBase is! Post) {
      if (widget.postBase is InnerFloor) {
        viewReplies = _buildReplyBtn('回复');
      } else if (widget.postBase is Floor) {
        final floor = widget.postBase as Floor;
        viewReplies = StreamBuilder(
          stream: _replyCntStreamController.stream,
          builder: (context, _) => _buildReplyBtn(
            floor.replyCnt > 0 ? '查看${floor.replyCnt}条回复>>' : '回复',
          ),
        );
      }
    }
    // 点赞
    Widget like = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => NormalButton(
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
      builder: (context, _) => NormalButton(
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
        if (viewReplies != null) viewReplies,
        Spacer(),
        like,
        dislike,
      ],
    );
    // 头像名字日期之下的部分
    Widget bottom = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (media != null) media.withMargin(top: 8.0, bottom: 8.0),
        buttons,
        Divider(color: Colors.grey[300], height: 1.0).withMargin(top: 8.0),
      ],
    );
    final leftSpace = widget.postBase is Post ? 12.0 : 60.0;
    bottom = Container(
      padding: EdgeInsets.only(left: leftSpace, right: 12.0),
      child: bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[top, bottom],
    );
  }

  // 回复按钮
  Widget _buildReplyBtn(String replyText) {
    return TextButton(
      child: Text(
        replyText,
        style: TextStyle(
          color: Colors.grey[500],
          fontWeight: FontWeight.normal,
        ),
      ),
      onPressed: widget.postBase is Floor
          // 查看回复按钮，有可能会返回新数量
          ? () async {
              final floor = widget.postBase as Floor;
              final result = await PostFloorRepliesSheet.show(context, floor);
              if (result != null && result is int) {
                floor.replyCnt = result;
                _replyCntStreamController?.send(null);
              }
            }
          // 回复按钮
          : widget.onReplyClick,
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

  // 图片和视频显示
  Widget _buildMedias(BuildContext context, List<UploadedFile> medias) {
    if (medias.isEmpty) return null;
    final list = <Widget>[];
    for (final m in medias) {
      if (m.type == FileType.image) {
        list.add(
          ImageWithUrl(
            m.thumbUrl,
            fit: BoxFit.cover,
            onPressed: () => _viewMediaImages(context, m, medias),
          ),
        );
      } else if (m.type == FileType.video) {
        list.add(AspectRatio(
          aspectRatio: 1.75,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ImageWithUrl(m.thumbUrl, fit: BoxFit.cover).positioned(),
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
    UploadedFile cur,
    List<UploadedFile> medias,
  ) {
    final images = medias.where((m) => m.type == FileType.image).toList();
    final idx = images.indexOf(cur);
    viewImages(context, images.map((e) => e.url).toList(), max(0, idx));
  }
}
