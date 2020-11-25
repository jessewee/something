import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:something/common/network.dart';
import 'package:something/common/pub.dart';

import '../common/view_images.dart';
import '../common/widgets.dart';
import '../common/models.dart';
import '../base/api/api.dart' as api;
import 'iconfont.dart';

/// 我的页面
class MePage extends StatefulWidget {
  static const routeName = '/me';

  @override
  _MePageState createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  User _user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('我的')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    _user = context.watch<UserVM>().user;
    final divider = Divider(
      color: Colors.grey[200],
      height: 1.0,
      thickness: 1.0,
      indent: 12.0,
      endIndent: 12.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头像
        _Item(
          '头像',
          tail: ImageWithUrl(
            _user.avatarThumb,
            round: true,
            width: 40,
            height: 40,
            backgroundColor: Colors.grey[200],
            errorWidget: Icon(Icons.emoji_people),
            onPressed: () => viewImages(context, [_user.avatar]),
          ),
          onTap: _changeAvatar,
        ),
        divider,
        // 名字
        _Item(
          '名字',
          content: _user.name,
          onTap: _changeName,
        ),
        divider,
        // 性别
        _Item(
          '性别',
          tail: _user.isGenderClear
              ? Icon(
                  _user.isMale ? Iconfont.male : Iconfont.female,
                  color: _user.isMale ? Colors.blue : Colors.pink,
                  size: 16.0,
                )
              : Text('未知', style: TextStyle(color: Colors.grey[800])),
          onTap: _changeGender,
        ),
        divider,
        // 生日
        _Item('生日', content: _user.birthday, onTap: _changeBirthday),
        divider,
        // 注册日期
        _Item('注册日期', content: _user.registerDate),
        divider,
        // 备注
        _Item(
          '备注',
          content: _user.remark,
          crossAxisAlignment: CrossAxisAlignment.start,
          onTap: _changeRemark,
        ),
        divider,
        // 退出登录
        Padding(
          padding: const EdgeInsets.fromLTRB(15.0, 50.0, 15.0, 25.0),
          child: OutlinedButton(
            onPressed: () {
              showAlertDialog(
                title: '确认',
                content: '确认要退出登录？',
                onConfirm: () {
                  context.read<UserVM>().user = User();
                  network.clearToken();
                  Navigator.pop(context);
                  return;
                },
              );
            },
            child: Text('退出登录'),
          ),
        ),
      ],
    );
  }

  // 修改名字
  void _changeName() {
    TextFieldSheet.show(
      context,
      defaultText: _user.name,
      maxLength: 20,
      onConfirmClick: (text) async {
        final result = await api.updateUserInfo(name: text);
        if (result.fail) {
          showToast(result.msg);
          return false;
        }
        setState(() => _user.name = text);
        return true;
      },
    );
  }

  // 修改性别
  Future _changeGender() async {
    final idx = await SelectionSheet.show(
      context,
      textSelections: ['男', '女', '不设置'],
    );
    if (idx == null) return;
    final gender = idx == 0
        ? Gender.male
        : idx == 1
            ? Gender.female
            : Gender.unknown;
    final result = await api.updateUserInfo(gender: gender);
    if (result.fail) {
      showToast(result.msg);
    } else {
      setState(() => _user.gender = gender);
    }
    return;
  }

  // 修改头像
  Future _changeAvatar() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final ur = await api.upload(pickedFile.path, FileType.image);
    if (ur.fail) {
      showToast(ur.msg);
      return;
    }
    final data = ur.data;
    final result =
        await api.updateUserInfo(avatar: data.url, avatarThumb: data.thumbUrl);
    if (result.fail) {
      showToast(result.msg);
      return;
    }
    setState(() {
      _user.avatar = data.url;
      _user.avatarThumb = data.thumbUrl;
    });
    return;
  }

  // 修改生日
  Future _changeBirthday() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_user.birthday) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    final date = '${selected.year}-${selected.month}-${selected.day}';
    final result = await api.updateUserInfo(birthday: date);
    if (result.fail) {
      showToast(result.msg);
    } else {
      setState(() => _user.birthday = date);
    }
    return;
  }

  // 修改备注
  void _changeRemark() {
    TextFieldSheet.show(
      context,
      defaultText: _user.remark,
      onConfirmClick: (text) async {
        final result = await api.updateUserInfo(remark: text);
        if (result.fail) {
          showToast(result.msg);
          return false;
        }
        setState(() => _user.remark = text);
        return true;
      },
    );
  }
}

class _Item extends StatefulWidget {
  final String label;
  final String content;
  final Widget tail;
  final Function onTap;
  final CrossAxisAlignment crossAxisAlignment;
  const _Item(
    this.label, {
    this.content,
    this.tail,
    this.onTap,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  __ItemState createState() => __ItemState();
}

class __ItemState extends State<_Item> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final loadingSize = Theme.of(context).textTheme.bodyText1.fontSize * 0.75;
    final child = Container(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: widget.crossAxisAlignment,
        children: [
          // loading
          if (_loading)
            Container(
              margin: const EdgeInsets.only(right: 5.0),
              width: loadingSize,
              height: loadingSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.grey),
              ),
            ),
          // 标签
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Text(widget.label),
          ),
          // 内容
          if (widget.content == null)
            Spacer()
          else
            Expanded(
              child: Container(
                alignment: Alignment.centerRight,
                child: Text(
                  widget.content,
                  style: TextStyle(
                    color: widget.onTap == null
                        ? Colors.grey[400]
                        : Colors.grey[800],
                  ),
                ),
              ),
            ),
          // 右边的widget
          if (widget.tail != null) widget.tail,
        ],
      ),
    );
    if (_loading || widget.onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: Colors.black26,
        highlightColor: Colors.black12,
        child: child,
        onTap: () {
          final result = widget.onTap();
          if (result is! Future) return;
          setState(() => _loading = true);
          result.then((_) {
            if (mounted) setState(() => _loading = false);
          });
        },
      ),
    );
  }
}
