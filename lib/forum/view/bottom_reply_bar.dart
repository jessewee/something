import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/models.dart';
import '../../common/pub.dart';
import '../../common/extensions.dart';
import '../../common/event_bus.dart';

import '../model/m.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;
import '../view/select_following_page.dart';
import 'post_long_content_sheet.dart';

class BottomReplyBar extends StatefulWidget {
  final ReplyVM vm;
  const BottomReplyBar(this.vm);

  @override
  _BottomReplyBarState createState() => _BottomReplyBarState();
}

class _BottomReplyBarState extends State<BottomReplyBar> {
  TextEditingController _controller;
  FocusNode _focusNode;
  StreamControllerWithData<bool> _sending;

  @override
  void initState() {
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _sending = StreamControllerWithData(false);
    super.initState();
  }

  @override
  void dispose() {
    _sending.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minHeight = 44.0;
    const tbPadding = 3.0;
    const iconSize = 24.0;
    const iconPadding = 7.0;
    const inputRadius = 19.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200])),
      ),
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: tbPadding,
      ),
      child: Row(
        children: <Widget>[
          // 发送中的loading
          StreamBuilder(
            stream: _sending.stream,
            builder: (context, snapshot) => Visibility(
              child: Container(
                margin: const EdgeInsets.only(right: 5.0),
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.grey),
                ),
              ),
              visible: snapshot.data == true,
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: _controller,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: widget.vm.hintText,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 8.0,
                ),
                fillColor: Colors.grey[100],
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(inputRadius)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(inputRadius)),
                  borderSide: BorderSide(color: Colors.transparent),
                ),
              ),
              onSubmitted: (text) => _onSubmit(text, []),
            ),
          ),
          // 长回复按钮
          FlatButton(
            padding: const EdgeInsets.all(iconPadding),
            child: Text('长回复'),
            onPressed: () => _onLongReplyClick(context),
          ),
          // @好友
          FlatButton(
            minWidth: 0,
            padding: const EdgeInsets.all(iconPadding),
            child: Icon(Icons.alternate_email, size: iconSize),
            onPressed: () => _onAtFriendClick(context),
          ),
        ],
      ),
    );
  }

  // 长回复
  void _onLongReplyClick(BuildContext context) async {
    _focusNode.unfocus();
    PostLongContentSheet.show(context, widget.vm);
  }

  // @某人
  void _onAtFriendClick(BuildContext context) async {
    dynamic user = await Navigator.pushNamed(
      context,
      SelectFollowingPage.routeName,
      arguments: true,
    );
    if (user != null && user is ForumUser) {
      _controller.text = '${_controller.text} @${user.name} ';
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  // 提交回复
  Future<bool> _onSubmit(String text, List<UploadedFile> medias) async {
    _sending.add(true);
    final result =
        await widget.vm.submit(context.read<UserVM>().user, text, medias);
    _sending.add(false);
    return result;
  }
}

class ReplyVM {
  /// 发帖时用这个参数
  final bool showLabel;

  /// 回复楼主时用这个参数
  final String postId;

  /// 回复层主时用这个参数，同时还必须传postId
  final String floorId;

  /// 回复非层主时用这个参数，同时还必须传floorId和postId
  final String innerFloorId;

  /// 层内回复目标id
  final String targetId;

  /// 层内回复目标名字
  final String targetName;

  final String defaultText;

  /// 回复成功的回调，会把回复内容封装成Post、Floor、InnerFloor对象
  final void Function(PostBase) onReplied;

  String get hintText => targetId?.isNotEmpty == true
      ? '回复$targetName'
      : postId?.isNotEmpty == true
          ? '回复楼主'
          : '回复层主';
  String postLabel = '';

  ReplyVM({
    this.showLabel,
    this.postId,
    this.floorId,
    this.innerFloorId,
    this.targetId,
    this.targetName,
    this.defaultText,
    this.onReplied,
  });

  Future<bool> submit(User user, String text, List<UploadedFile> medias) async {
    // 层内回复
    if (innerFloorId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        floorId: floorId,
        innerFloorId: innerFloorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
        targetId: targetId ?? '',
        targetName: targetName ?? '',
        postId: postId,
        floorId: floorId,
      ));
      return true;
    }
    // 回复层主
    if (floorId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        floorId: floorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
        postId: postId,
        floorId: floorId,
      ));
      return true;
    }
    // 回复楼主
    if (postId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: postId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      onReplied(Floor(
        id: result.data.floorId,
        posterId: user.id,
        avatar: user.avatar,
        avatarThumb: user.avatarThumb,
        name: user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        floor: result.data.floor,
        postId: postId,
      ));
      return true;
    }
    // 发帖
    if (postLabel?.isNotEmpty != true) return false;
    final result = await repository.post(
      label: postLabel,
      content: text,
      mediaIds: medias.map((e) => e.id).toList(),
    );
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    eventBus.sendEvent(
      EventBusType.forumPosted,
      Post(
          id: result.data,
          posterId: user.id,
          avatar: user.avatar,
          avatarThumb: user.avatarThumb,
          name: user.name,
          date: DateTime.now().format(),
          content: text,
          medias: medias),
    );
    return true;
  }
}
