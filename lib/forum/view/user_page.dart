import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/widgets.dart';
import '../../common/pub.dart';
import '../../common/models.dart';
import '../../common/view_images.dart';
import '../../common/extensions.dart';

import '../model/m.dart';
import '../../base/iconfont.dart';
import '../repository/repository.dart' as repository;
import 'user_follow_page.dart';
import 'user_post_page.dart';
import 'user_reply_page.dart';

/// 用户信息页
class UserPage extends StatefulWidget {
  static const routeName = '/forum/user';
  final String userId;

  UserPage(this.userId);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  StreamController<bool> _followStreamController; // 关注按钮改变
  bool _myself;

  @override
  void initState() {
    _followStreamController = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _followStreamController.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_myself == null)
      _myself = widget.userId == context.watch<UserVM>().user.id;
    return Scaffold(
      appBar: AppBar(title: Text('用户信息')),
      body: SingleChildScrollView(
        child: FutureBuilder<Result<ForumUser>>(
          future: repository.getUserInfo(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CenterInfoText('加载中...');
            }
            if (snapshot.data.fail) {
              return CenterInfoText(snapshot.data.msg);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: _buildContent(context, snapshot.data.data),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ForumUser user) {
    final divider = Divider(
      color: Colors.grey[200],
      height: 1.0,
      thickness: 1.0,
      indent: 12.0,
      endIndent: 12.0,
    );
    final theme = Theme.of(context);
    return Column(
      children: [
        // 名字、性别
        _buildItem(
          '名字',
          content: user.name,
          mid: user.isGenderClear
              ? Icon(
                  user.isMale ? Iconfont.male : Iconfont.female,
                  color: user.isMale ? Colors.blue : Colors.pink,
                  size: 16.0,
                )
              : null,
        ),
        divider,
        // 头像
        _buildItem(
          '头像',
          tail: ImageWithUrl(
            user.avatarThumb,
            round: true,
            width: 40,
            height: 40,
            backgroundColor: Colors.grey[200],
            errorWidget: Icon(Icons.emoji_people),
            onPressed: () => viewImages(context, [user.avatar]),
          ),
        ),
        divider,
        // 生日
        _buildItem('生日', content: user.birthday),
        divider,
        // 注册日期
        _buildItem('注册日期', content: user.registerDate),
        divider,
        // 关注的人数、粉丝数量
        _buildButtonItem(
          '关注${user.followingCount}',
          '粉丝${user.followerCount}',
          () => Navigator.pushNamed(
            context,
            UserFollowPage.routeName,
            arguments: UserFollowPageArg(user.id, true),
          ),
          () => Navigator.pushNamed(
            context,
            UserFollowPage.routeName,
            arguments: UserFollowPageArg(user.id, false),
          ),
        ),
        divider,
        // 发帖数量、回复数量
        _buildButtonItem(
          '发帖${user.postCount}',
          '回复${user.replyCount}',
          () => Navigator.pushNamed(
            context,
            UserPostPage.routeName,
            arguments: UserPostPageArg(user.id, user.name),
          ),
          () => Navigator.pushNamed(
            context,
            UserReplyPage.routeName,
            arguments: user.id,
          ),
        ),
        divider,
        // 备注
        _buildItem('备注', content: user.remark),
        divider,
        // 关注按钮
        if (_myself != true)
          StreamBuilder<bool>(
            stream: _followStreamController.stream,
            builder: (context, snapshot) => NormalButton(
              color:
                  user.followed ? theme.primaryColorLight : theme.primaryColor,
              text: user.followed ? '已关注' : '关注',
              onPressed: () async {
                await repository.follow(user.id, !user.followed);
                _followStreamController.send(null);
              },
            ),
          )
      ],
    );
  }

  Widget _buildItem(String label, {String content, Widget tail, Widget mid}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(label),
          ),
          if (mid != null)
            Padding(padding: const EdgeInsets.only(right: 8.0), child: mid),
          if (content == null)
            Spacer()
          else
            Expanded(child: Text(content, textAlign: TextAlign.end)),
          if (tail != null) tail,
        ],
      ),
    );
  }

  Widget _buildButtonItem(
    String left,
    String right,
    VoidCallback onLeftClick,
    VoidCallback onRightClick,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(onPressed: onLeftClick, child: Text(left)),
          ),
          Expanded(
            child: TextButton(onPressed: onRightClick, child: Text(right)),
          ),
        ],
      ),
    );
  }
}
