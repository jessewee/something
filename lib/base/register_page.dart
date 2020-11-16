import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/widgets.dart';
import '../common/pub.dart';
import '../common/extensions.dart';
import 'api/api.dart' as api;

/// 注册页
class RegisterPage extends StatefulWidget {
  static const routeName = '/register';

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _account = '';
  String _pwd = '';
  String _email = '';
  String _vfCode = '';

  StreamControllerWithData<bool> _vfCodeBtnStreamController; // 控制发送验证码按钮的显示
  StreamControllerWithData<bool> _confirmBtnStreamController; // 控制注册按钮的加载中状态显示

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
      appBar: AppBar(title: Text('注册')),
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
                // 密码
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: '密码'),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  onChanged: (text) => _pwd = text,
                  validator: (text) => text.trim().isEmpty ? '请输入密码' : null,
                ),
                // 确认密码
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: '确认密码'),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  validator: (text) {
                    if (text.trim().isEmpty) return '请确认密码';
                    if (text != _pwd) return '两次密码输入不一致';
                    return null;
                  },
                ),
                // 邮箱，发送验证码按钮
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: '邮箱',
                          hintText: '用来找回密码，可不填',
                        ),
                        maxLength: 20,
                        textInputAction: TextInputAction.done,
                        onChanged: (text) {
                          _email = text;
                          _vfCodeBtnStreamController.reAdd();
                        },
                        validator: (text) => null,
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
                  validator: (text) => text.trim().isEmpty && _email.isNotEmpty
                      ? '请输入验证码'
                      : null,
                ),
                // 确定按钮
                Builder(
                  builder: (context) => StreamBuilder<Object>(
                    stream: _confirmBtnStreamController.stream,
                    builder: (context, snapshot) => NormalButton(
                      backgroundColor: Theme.of(context).primaryColor,
                      text: '注册',
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      onPressed: () => _register(context),
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

  // 注册
  Future _register(BuildContext context) async {
    if (Form.of(context).validate()) {
      _confirmBtnStreamController.add(true);
      final result = await api.register(
        _account,
        _pwd,
        _email,
        _vfCode,
      );
      _confirmBtnStreamController.add(false);
      if (result.fail) {
        showToast(result.msg);
        return;
      }
      showToast('注册成功');
      Navigator.pop(context);
    }
    return;
  }
}
