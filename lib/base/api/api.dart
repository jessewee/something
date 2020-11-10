import '../../common/pub.dart';
import '../../common/models.dart';
import '../../common/network.dart';

/// 获取邮箱验证码
Future<Result> getEmailVfCode(String email) async {
  return await network.get('/get_vf_code', params: {'email': email});
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
  return await network.put('/reset_pwd', params: {
    'account': account,
    'pwd': newPwd,
    'vfcode': vfCode,
  });
}

/// 登录
Future<Result> login(String account, String pwd) async {
  return await network.get('/login', params: {'account': account, 'pwd': pwd});
}

/// 获取用户数据
Future<Result<User>> getUserInfo() async {
  final tmp = await network.get('/get_user_info');
  if (tmp.fail) return Result(code: tmp.code, msg: tmp.msg);
  final map = tmp.data;
  return Result.success(User(
    id: map['id'],
    name: map['name'],
    avatar: map['avatar'],
    avatarThumb: map['avatarThumb'],
    // gender: map['gender'],
    birthday: map['birthday'],
    registerDate: map['registerDate'],
  ));
}
