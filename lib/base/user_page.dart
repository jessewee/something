import 'package:flutter/material.dart';

import '../common/widgets.dart';
import '../common/pub.dart';
import '../common/models.dart';
import '../common/view_images.dart';
import '../base/api/api.dart' as api;
import 'iconfont.dart';

/// 用户信息页
class UserPage extends StatefulWidget {
  static const routeName = 'user';
  final UserPageArg arg;

  UserPage(this.arg);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('用户信息')),
      body: FutureBuilder<Result<User>>(
        future: api.getUserInfo(
          userId: widget.arg.userId,
          userName: widget.arg.userName,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CenterInfoText('加载中...');
          }
          if (snapshot.data.fail) {
            return CenterInfoText(snapshot.data.msg);
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              child: _buildContent(context, snapshot.data.data),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, User user) {
    final divider = Divider(
      color: Colors.grey[200],
      height: 1.0,
      thickness: 1.0,
      indent: 12.0,
      endIndent: 12.0,
    );
    return Column(
      children: [
        // 名字、性别
        _buildItem(
          '名字',
          content: user.name,
          tail: user.isGenderClear
              ? Icon(
                  user.isMale ? Iconfont.male : Iconfont.female,
                  color: user.isMale ? Colors.blue : Colors.pink,
                  size: 12.0,
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
        // 备注
        _buildItem('备注', content: user.remark),
        divider,
      ],
    );
  }

  Widget _buildItem(
    String label, {
    String content,
    Widget tail,
    Widget mid,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
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
          if (tail != null)
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: tail,
            ),
        ],
      ),
    );
  }
}

class UserPageArg {
  final String userId;
  final String userName;
  UserPageArg({this.userId, this.userName});
}
