import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:something/common/event_bus.dart';

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
  List<TapGestureRecognizer> _tapGestureRecognizers; // 点击目标对象

  @override
  void initState() {
    _likeStatusStreamController = StreamController.broadcast();
    if (widget.postBase is Post) {
      _followStreamController = StreamController();
      // 在其它页改变了关注状态
      final post = widget.postBase as Post;
      eventBus.on(EventBusType.forumUserChanged, (arg) {
        if (arg == null || arg is! Map) return;
        if (arg['userId'] != widget.postBase.posterId) return;
        if (arg['followed'] == null) return;
        final followed = arg['followed'] as bool;
        if (followed != post.posterFollowed) {
          post.posterFollowed = followed;
          _followStreamController.send(null);
        }
      }, 'post_list_item');
    } else if (widget.postBase is Floor) {
      _replyCntStreamController = StreamController();
    }
    _tapGestureRecognizers = [];
    super.initState();
  }

  @override
  void dispose() {
    if (widget.postBase is Post) eventBus.off(tag: 'post_list_item');
    _tapGestureRecognizers.forEach((e) => e.dispose());
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
    // 楼层和日期
    String dateText;
    if (widget.postBase is Floor) {
      final floor = widget.postBase as Floor;
      dateText = '第${floor.floor}楼 · ${floor.date}';
    } else if (widget.postBase is InnerFloor) {
      final innerFloor = widget.postBase as InnerFloor;
      dateText = '第${innerFloor.innerFloor}楼 · ${innerFloor.date}';
    } else {
      dateText = widget.postBase.date;
    }
    Widget date = Text(dateText, style: theme.textTheme.caption);
    // 关注按钮
    Widget follow;
    if (widget.postBase is Post) {
      final post = widget.postBase as Post;
      follow = StreamBuilder<bool>(
        stream: _followStreamController.stream,
        builder: (context, _) => NormalButton(
          color: post.posterFollowed ? theme.primaryColorLight : theme.primaryColor,
          text: post.posterFollowed ? '已关注' : '关注',
          onPressed: _onFollowClick,
        ),
      );
    }
    // 头像、名字、楼层和日期区域
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
    List<InlineSpan> contentSpans = [];
    if (widget.postBase is InnerFloor && (widget.postBase as InnerFloor).targetId?.isNotEmpty == true) {
      final innerFloor = widget.postBase as InnerFloor;
      contentSpans.add(TextSpan(text: '回复'));
      // 点击事件
      final tgr = TapGestureRecognizer()
        ..onTap = () {
          final targetId = (widget.postBase as InnerFloor).targetId;
          Navigator.pushNamed(
            context,
            UserPage.routeName,
            arguments: UserPageArg(userId: targetId),
          );
        };
      _tapGestureRecognizers.add(tgr);
      // 名字显示
      contentSpans.add(TextSpan(
        text: innerFloor.targetName,
        style: TextStyle(color: Colors.blue),
        recognizer: tgr,
      ));
      contentSpans.add(TextSpan(text: '： '));
    }
    if (widget.postBase.content.contains('@')) {
      var text = widget.postBase.content;
      var idx = -1;
      while ((idx = text.indexOf('@')) >= 0) {
        if (idx > 0) contentSpans.add(TextSpan(text: text.substring(0, idx)));
        var endIdx = text.indexOf(' ', idx);
        if (endIdx < 0) endIdx = text.length - 1;
        if (endIdx > idx + 1) {
          final target = text.substring(idx + 1, endIdx + 1);
          // 点击事件
          final tgr = TapGestureRecognizer()
            ..onTap = () {
              Navigator.pushNamed(
                context,
                UserPage.routeName,
                arguments: UserPageArg(userName: target.trim()),
              );
            };
          _tapGestureRecognizers.add(tgr);
          // 名字显示
          contentSpans.add(TextSpan(
            text: '@$target',
            style: TextStyle(color: Colors.blue),
            recognizer: tgr,
          ));
        }
        text = text.substring(endIdx + 1);
      }
      contentSpans.add(TextSpan(text: text));
    } else {
      contentSpans.add(TextSpan(text: widget.postBase.content));
    }
    Widget content = RichText(
      text: TextSpan(
        style: TextStyle(color: theme.textTheme.bodyText1.color),
        children: contentSpans,
      ),
    );
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
        color: widget.postBase.myAttitude == true ? theme.primaryColor : Colors.black,
        icon: Iconfont.like,
        text: '${widget.postBase.likeCnt}',
        onPressed: _onLikeClick,
      ),
    );
    // 点踩
    Widget dislike = StreamBuilder(
      stream: _likeStatusStreamController.stream,
      builder: (context, _) => NormalButton(
        color: widget.postBase.myAttitude == false ? theme.primaryColor : Colors.black,
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
        if (widget.postBase is! Post) Divider(color: Colors.grey[300], height: 1.0).withMargin(top: 8.0),
      ],
    );
    final leftSpace = widget.postBase is Post ? 12.0 : 60.0;
    bottom = Container(
      padding: EdgeInsets.only(left: leftSpace, right: 12.0),
      child: bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        top,
        bottom,
        if (widget.postBase is Post) Divider(color: Colors.grey[100], height: 20, thickness: 20).withMargin(top: 8.0),
      ],
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
    final target = widget.postBase.myAttitude == true ? null : true;
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
    final target = widget.postBase.myAttitude == false ? null : false;
    final result = await widget.postBase.changeLikeState(target);
    if (result.isNotEmpty) {
      showToast(result);
    } else {
      _likeStatusStreamController.send(null);
    }
    return;
  }

  // 查看发布人
  void _onViewUserClick() {
    Navigator.pushNamed(
      context,
      UserPage.routeName,
      arguments: UserPageArg(userId: widget.postBase.posterId),
    );
  }

  // 关注按钮
  Future _onFollowClick() async {
    final post = widget.postBase as Post;
    final result = await post.changeFollowPosterStatus();
    if (result.isNotEmpty) {
      showToast(result);
      return;
    }
    _followStreamController.send(null);
    eventBus.sendEvent(
      EventBusType.forumUserChanged,
      {'userId': post.posterId, 'followed': post.posterFollowed},
    );
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
            aspectRatio: m.aspectRatio,
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
    viewImages(
      context,
      images.map((e) => e.url).toList(),
      curIndex: max(0, idx),
    );
  }
}
