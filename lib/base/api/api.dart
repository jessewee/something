import '../../common/pub.dart';
import '../../common/models.dart';
import '../../common/network.dart';

/// 获取邮箱验证码
Future<Result> getEmailVfCode(String email) async {
  return await network.post('/get_vf_code', params: {'email': email});
}

/// 注册
Future<Result> register(
  String account,
  String pwd,
  String email,
  String vfCode,
) async {
  return await network.post('/register', params: {
    'account': account,
    'pwd': pwd,
    'email': email,
    'vfcode': vfCode
  });
}

/// 重置密码
Future<Result> retrievePwd(String account, String vfCode, String newPwd) async {
  return await network.post('/reset_pwd', params: {
    'account': account,
    'pwd': newPwd,
    'vfcode': vfCode,
  });
}

/// 登录
Future<Result> login(String account, String pwd) async {
  return await network.post('/login', params: {'account': account, 'pwd': pwd});
}

/// 获取用户数据
Future<Result<User>> getUserInfo() async {
  // TODO
  await Future.delayed(Duration(seconds: 1));
  // if (Random.secure().nextBool()) {
  //   return Future.value(Result(msg: "获取用户信息失败"));
  // } else {
  return Future.value(
    Result.success(
      User(
        id: '0',
        name: '名字',
        avatar: '',
        gender: Gender.male,
        birthday: '',
        registerDate: '',
      ),
    ),
  );
  // }
}
