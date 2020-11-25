import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/models.dart';
import '../../common/pub.dart';

import '../vm/reply_vm.dart';
import '../model/m.dart';
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
    if (result) _controller.text = '';
    return result;
  }
}
