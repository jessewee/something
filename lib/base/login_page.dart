import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../common/widgets.dart';
import '../common/pub.dart';
import '../common/models.dart';
import '../common/extensions.dart';
import 'api/api.dart' as api;
import 'register_page.dart';
import 'retrieve_pwd_page.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  static const routeName = 'login';
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamController<bool> _loginBtnSc;
  String _account;
  String _pwd;

  // 是否可登录
  get _loginable => this._account?.isNotEmpty == true && this._pwd?.isNotEmpty == true;

  @override
  void initState() {
    _loginBtnSc = StreamController();
    super.initState();
  }

  @override
  void dispose() {
    _loginBtnSc.makeSureClosed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(50.0, 100.0, 50.0, 50.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // logo
            Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: FlutterLogo(size: 100.0),
            ),
            // 账号输入框
            _InputWidget(onChanged: (text) => _onTextChanged(account: text)),
            // 密码输入框
            _InputWidget(
              onChanged: (text) => _onTextChanged(pwd: text),
              flag: false,
            ),
            // 注册账号和找回密码
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FlatButton(
                  child: Text('注册账号'),
                  onPressed: () => Navigator.of(context).pushNamed(RegisterPage.routeName),
                ),
                FlatButton(
                  child: Text('找回密码'),
                  onPressed: () => Navigator.of(context).pushNamed(RetrievePwdPage.routeName),
                ),
              ],
            ),
            // 登录按钮
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: StreamBuilder<bool>(
                initialData: false,
                stream: _loginBtnSc.stream,
                builder: (context, snapshot) => NormalButton(
                  text: '登录',
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  onPressed: snapshot.data ? _onLoginClick : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 输入框文字改变
  void _onTextChanged({String account, String pwd}) {
    bool oldState = _loginable;
    if (account != null) this._account = account;
    if (pwd != null) this._pwd = pwd;
    if (mounted && _loginable != oldState) _loginBtnSc?.add(_loginable);
  }

  // 点击登录按钮
  Future<void> _onLoginClick() async {
    var result = await api.login(_account, _pwd);
    if (result.fail) {
      showToast(result.msg);
      return;
    }
    result = await api.getUserInfo();
    if (result.fail) {
      showToast(result.msg);
      return;
    }
    context.read<UserVM>().user = result.data;
    Navigator.pop(context, true);
    return;
  }
}

class _InputWidget extends StatelessWidget {
  final flag; // true:账号、false:密码
  final Function(String) onChanged;
  final Function onSubmitted;

  const _InputWidget({this.flag = true, this.onChanged, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      decoration: ShapeDecoration(shape: StadiumBorder(), color: Colors.white),
      child: Row(
        children: <Widget>[
          // 账号密码图标
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(flag ? Icons.person : Icons.lock),
          ),
          // 输入框
          Expanded(
            child: TextField(
              autofocus: false,
              textInputAction: flag ? TextInputAction.next : TextInputAction.done,
              onSubmitted: (value) => onSubmitted?.call(),
              decoration: InputDecoration(
                hintText: flag ? "请输入账号" : "请输入密码",
                contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
              ),
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              obscureText: !flag,
              onChanged: (text) => onChanged?.call(text),
            ),
          ),
        ],
      ),
    );
  }
}
