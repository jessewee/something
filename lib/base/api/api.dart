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
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    avatar: map['avatar'] ?? '',
    avatarThumb: map['avatar_thumb'] ?? '',
    gender: GenderExt.fromName(map['gender']),
    birthday: map['birthday'] ?? '',
    registerDate: map['register_date'] ?? '',
    remark: map['remark'] ?? '',
  ));
}

/// 更改用户信息
Future<Result> updateUserInfo({
  String name,
  String avatar,
  String avatarThumb,
  Gender gender,
  String birthday,
  String remark,
}) async {
  final params = {};
  if (name?.isNotEmpty == true) params['name'] = name;
  if (avatar?.isNotEmpty == true) params['avatar'] = avatar;
  if (avatarThumb?.isNotEmpty == true) params['avatarThumb'] = avatarThumb;
  if (gender != null) params['gender'] = gender.name;
  if (birthday?.isNotEmpty == true) params['birthday'] = birthday;
  if (remark?.isNotEmpty == true) params['remark'] = remark;
  return await network.put('/update_user_info', params: params);
}

/// 上传文件
Future<Result<UploadedFile>> upload(
  String path,
  FileType type, {
  String tag,
}) async {
  final result = await network.post(
    '/upload',
    params: {'type': type.name},
    filePaths: [path],
    tag: tag,
  );
  if (result.fail) return result;
  return Result.success(UploadedFile(
      id: result.data['id'],
      type: FileTypeExt.fromName(result.data['type']),
      url: result.data['url'],
      thumbUrl: result.data['thumb_url']));
}
