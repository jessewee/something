import 'package:flutter/material.dart';

import '../common/widgets.dart';
import '../common/pub.dart';
import '../common/extensions.dart';
import 'api/api.dart' as api;

/// 找回密码页
class RetrievePwdPage extends StatefulWidget {
  static const routeName = 'retrieve_pwd';

  @override
  _RetrievePwdPageState createState() => _RetrievePwdPageState();
}

class _RetrievePwdPageState extends State<RetrievePwdPage> {
  String _account = '';
  String _pwd = '';
  String _email = '';
  String _vfCode = '';

  StreamControllerWithData<bool> _vfCodeBtnStreamController; // 控制发送验证码按钮的显示
  StreamControllerWithData<bool> _confirmBtnStreamController; // 控制确定按钮的加载中状态显示

  @override
  void initState() {
    _vfCodeBtnStreamController = StreamControllerWithData(false);
    _confirmBtnStreamController = StreamControllerWithData(false);
    super.initState();
  }

  @override
  void dispose() {
    _vfCodeBtnStreamController.dispose();
    _confirmBtnStreamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('找回密码')),
      body: Container(
        padding: const EdgeInsets.fromLTRB(25.0, 20.0, 25.0, 10.0),
        child: SingleChildScrollView(
          child: Form(
            autovalidateMode: AutovalidateMode.always,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 账号
                TextFormField(
                  decoration: InputDecoration(labelText: '账号'),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  onChanged: (text) => _account = text,
                  validator: (text) => text.trim().isEmpty ? '请输入账号' : null,
                ),
                // 邮箱，发送验证码按钮
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: '邮箱'),
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        onChanged: (text) {
                          _email = text;
                          _vfCodeBtnStreamController.reAdd();
                        },
                        validator: (text) => text.trim().isEmpty ? '请输入邮箱' : null,
                        onFieldSubmitted: (_) => _sendEmailVfCode(),
                      ),
                    ),
                    StreamBuilder(
                      initialData: _vfCodeBtnStreamController.value,
                      stream: _vfCodeBtnStreamController.stream,
                      builder: (context, snapshot) => NormalButton(
                        text: '发送验证码',
                        loading: snapshot.data == true,
                        onPressed: _email.isEmpty ? null : _sendEmailVfCode,
                      ),
                    ),
                  ],
                ),
                // 验证码
                TextFormField(
                  decoration: InputDecoration(labelText: '验证码'),
                  maxLength: 6,
                  onChanged: (text) => _vfCode = text,
                  validator: (text) => text.trim().isEmpty ? '请输入验证码' : null,
                ),
                // 密码
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: '新密码'),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  onChanged: (text) => _pwd = text,
                  validator: (text) => text.trim().isEmpty ? '请输入新密码' : null,
                ),
                // 确认密码
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: '确认新密码'),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  validator: (text) {
                    if (text.trim().isEmpty) return '请确认新密码';
                    if (text != _pwd) return '两次密码输入不一致';
                    return null;
                  },
                ),
                // 确定按钮
                Builder(
                  builder: (context) => StreamBuilder<Object>(
                    stream: _confirmBtnStreamController.stream,
                    builder: (context, snapshot) => NormalButton(
                      backgroundColor: Theme.of(context).primaryColor,
                      text: '确定',
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      onPressed: () => _retrievePwd(context),
                    ),
                  ),
                ).withMargin(top: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 发送邮箱验证码
  Future<void> _sendEmailVfCode() async {
    if (_email.isEmpty) return;
    _vfCodeBtnStreamController.add(true);
    final result = await api.getEmailVfCode(_email);
    _vfCodeBtnStreamController.add(false);
    if (result.fail) {
      showToast(result.msg);
    } else {
      showToast('验证码发送成功');
    }
  }

  // 确定
  Future _retrievePwd(BuildContext context) async {
    if (Form.of(context).validate()) {
      _confirmBtnStreamController.add(true);
      final result = await api.retrievePwd(_account, _vfCode, _pwd);
      _confirmBtnStreamController.add(false);
      if (result.fail) {
        showToast(result.msg);
        return;
      }
      showToast('密码重置成功');
      Navigator.pop(context);
    }
    return;
  }
}
