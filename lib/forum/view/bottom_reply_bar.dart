import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/models.dart';
import '../../common/pub.dart';
import '../../common/extensions.dart';

import '../model/m.dart';
import '../model/post.dart';
import '../repository/repository.dart' as repository;
import '../view/select_following_page.dart';
import 'post_long_content_sheet.dart';

class BottomReplyBar extends StatefulWidget {
  /// 回复楼主时用这个参数
  final String postId;

  /// 回复层主时用这个参数
  final String floorId;

  /// 回复非层主时用这个参数
  final String innerFloorId;

  /// 层内回复目标id
  final String targetId;

  /// 层内回复目标名字
  final String targetName;

  /// 回复成功的回调，会把回复内容封装成Post、Floor、InnerFloor对象
  final void Function(PostBase) onReplied;

  const BottomReplyBar({
    this.postId,
    this.floorId,
    this.innerFloorId,
    this.targetId,
    this.targetName,
    this.onReplied,
  });

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
    final hintText = widget.targetName?.isNotEmpty == true
        ? '回复${widget.targetName}'
        : widget.postId?.isNotEmpty == true
            ? '回复楼主'
            : '回复层主';
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
                hintText: hintText,
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
    PostLongContentSheet.show(context, _controller.text, _onSubmit);
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
  Future<bool> _onSubmit(String text, List<Media> medias) async {
    _sending.add(true);
    final result = await _doSubmit(text, medias);
    _sending.add(false);
    return result;
  }

  Future<bool> _doSubmit(String text, List<Media> medias) async {
    // 回复楼主
    if (widget.postId?.isNotEmpty == true) {
      final result = await repository.reply(
        postId: widget.postId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<UserVM>();
      widget.onReplied(Floor(
        id: result.data.floorId,
        posterId: loginUser.user.id,
        avatar: loginUser.user.avatar,
        avatarThumb: loginUser.user.avatarThumb,
        name: loginUser.user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        floor: result.data.floor,
      ));
      _controller.text = '';
      return true;
    }
    // 回复层主
    if (widget.floorId?.isNotEmpty == true) {
      final result = await repository.reply(
        floorId: widget.floorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<UserVM>();
      widget.onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: loginUser.user.id,
        avatar: loginUser.user.avatar,
        avatarThumb: loginUser.user.avatarThumb,
        name: loginUser.user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
      ));
      _controller.text = '';
      return true;
    }
    // 层内回复
    if (widget.innerFloorId?.isNotEmpty == true) {
      final result = await repository.reply(
        innerFloorId: widget.innerFloorId,
        content: text,
        mediaIds: medias.map((e) => e.id).toList(),
      );
      if (result.fail) {
        showToast(result.msg);
        return false;
      }
      final loginUser = context.read<UserVM>();
      widget.onReplied(InnerFloor(
        id: result.data.innerFloorId,
        posterId: loginUser.user.id,
        avatar: loginUser.user.avatar,
        avatarThumb: loginUser.user.avatarThumb,
        name: loginUser.user.name,
        date: DateTime.now().format(),
        content: text,
        medias: medias,
        innerFloor: result.data.innerFloor,
        targetId: widget.targetId ?? '',
        targetName: widget.targetName ?? '',
      ));
      _controller.text = '';
      return true;
    }
    return false;
  }
}
