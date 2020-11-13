import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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
    _user = context.read<UserVM>().user;
    final divider = const Divider(
      color: Colors.blueGrey,
      height: 1.0,
      thickness: 1.0,
      indent: 12.0,
      endIndent: 12.0,
    );
    return Column(
      children: [
        // 名字
        _Item(
          '名字',
          content: _user.name,
          onTap: () async {
            await TextFileSheet.show(
              context,
              _changeName,
              defaultText: _user.name,
              maxLength: 20,
            );
          },
        ),
        divider,
        // 性别
        _Item(
          '性别',
          content: _user.name,
          tail: _user.isGenderClear
              ? Icon(
                  _user.isMale ? Iconfont.male : Iconfont.female,
                  color: _user.isMale ? Colors.blue : Colors.pink,
                )
              : null,
          onTap: _changeGender,
        ),
        divider,
        // 头像
        _Item(
          '头像',
          tail: ImageWithUrl(
            _user.avatarThumb,
            round: true,
            width: 40,
            height: 40,
            onPressed: () => viewImages(context, [_user.avatar]),
          ),
          onTap: _changeAvatar,
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
          onTap: () async {
            await TextFileSheet.show(
              context,
              _changeRemark,
              defaultText: _user.remark,
            );
          },
        ),
        divider,
      ],
    );
  }

  // 修改名字
  Future<bool> _changeName(String text) async {
    final result = await api.updateUserInfo(name: text);
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    setState(() => _user.name = text);
    return true;
  }

  // 修改性别
  Future _changeGender() async {
    final screenW = MediaQuery.of(context).size.width;
    final gender = await showDialog(
      context: context,
      builder: (context) => Container(
        width: screenW / 3,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextButton(
              child: Row(
                children: [
                  Text('男'),
                  Icon(Iconfont.male, color: Colors.blue),
                ],
              ),
              onPressed: () => Navigator.pop(context, Gender.male),
            ),
            TextButton(
              child: Row(
                children: [
                  Text('女'),
                  Icon(Iconfont.female, color: Colors.pink),
                ],
              ),
              onPressed: () => Navigator.pop(context, Gender.female),
            ),
            TextButton(
              child: Text('不设置'),
              onPressed: () => Navigator.pop(context, Gender.unknown),
            ),
          ],
        ),
      ),
    );
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
    final result = await api.upload(pickedFile.path, FileType.image);
    if (result.fail) {
      showToast(result.msg);
    } else {
      setState(() {
        _user.avatar = result.data.url;
        _user.avatarThumb = result.data.thumbUrl;
      });
    }
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
  Future<bool> _changeRemark(String text) async {
    final result = await api.updateUserInfo(remark: text);
    if (result.fail) {
      showToast(result.msg);
      return false;
    }
    setState(() => _user.remark = text);
    return true;
  }
}

class _Item extends StatefulWidget {
  final String label;
  final String content;
  final Widget tail;
  final Function onTap;
  const _Item(
    this.label, {
    this.content,
    this.tail,
    this.onTap,
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
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(widget.label),
          ),
          // 内容
          if (widget.content == null)
            Spacer()
          else
            Expanded(child: Text(widget.content, textAlign: TextAlign.end)),
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
