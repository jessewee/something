import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configs.dart';
import 'event_bus.dart';
import 'pub.dart';

Network get network => Network();

/// 接口请求
class Network {
  Dio _dio;
  static Network _singleton;

  factory Network() {
    if (_singleton == null) _singleton = Network._init();
    return _singleton;
  }

  // tag和CancelToken
  final _cancelTokens = Map<String, CancelToken>();

  // token，验证账号
  var _token = '';

  // 用来更新token
  var __refreshToken = '';

  set _refreshToken(value) {
    __refreshToken = value;
    SharedPreferences.getInstance()
        .then((sp) => sp.setString('login_refresh_token', value));
  }

  Future<String> get _refreshToken async {
    if (__refreshToken.isEmpty) {
      var sp = await SharedPreferences.getInstance();
      __refreshToken = sp.getString('login_refresh_token') ?? '';
    }
    return __refreshToken;
  }

  void clearToken() {
    _token = '';
    __refreshToken = '';
    SharedPreferences.getInstance().then((sp) => sp.clear());
  }

  Network._init() {
    _dio = Dio();
    _dio.options.baseUrl = apiServer;
    // _dio.options.connectTimeout = 5000;
    // _dio.options.receiveTimeout = 5000;
    _dio.interceptors.add(CookieManager(CookieJar()));
    _dio.interceptors
        .add(LogInterceptor(requestBody: true, responseBody: true));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options) async {
        // 给header赋值token，或者发送refreshToken来刷新token
        if (_token.isNotEmpty) {
          options.headers['token'] = _token;
        } else {
          final tmp = await _refreshToken;
          if (tmp.isNotEmpty) options.headers['refresh_token'] = tmp;
        }
        return options;
      },
      onResponse: (e) async {
        // 保存服务器返回的token
        final token = e.headers?.value('token') ?? '';
        if (token.isNotEmpty) _token = token;
        final refreshToken = e.headers?.value('refresh_token') ?? '';
        if (refreshToken.isNotEmpty) _refreshToken = refreshToken;
        return e;
      },
      onError: (e) {
        showToast('网络出错：${e.message}');
        return Response();
      },
    ));
  }

  /// GET请求 [tag]用来标记请求，取消时用到，比如离开页面时取消网络请求
  Future<Result> get(
    String path, {
    Map<String, dynamic> params = const {},
    String tag,
    bool checkLogin = true,
  }) async {
    if (checkLogin && await _needLogin(path)) {
      eventBus.sendEvent(EventBusType.loginInvalid);
      return Result(msg: '请先登录');
    }
    Response<String> response = await _dio.get(
      path,
      queryParameters: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = await toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return get(path, params: params, tag: tag);
    }
    return result;
  }

  /// POST请求
  Future<Result> post(
    String path, {
    Map<String, dynamic> params = const {},
    List<String> filePaths = const [],
    String tag,
  }) async {
    if (await _needLogin(path)) {
      eventBus.sendEvent(EventBusType.loginInvalid);
      return Result(msg: '请先登录');
    }
    final formData = FormData.fromMap(params);
    for (int i = 0; i < filePaths.length; i++) {
      formData.files.add(
        MapEntry(i.toString(), await MultipartFile.fromFile(filePaths[i])),
      );
    }
    Response response = await _dio.post(
      path,
      data: formData,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = await toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return post(path, params: params, tag: tag);
    }
    return result;
  }

  /// PUT请求
  Future<Result> put(
    String path, {
    Map<String, dynamic> params = const {},
    String tag,
  }) async {
    if (await _needLogin(path)) {
      eventBus.sendEvent(EventBusType.loginInvalid);
      return Result(msg: '请先登录');
    }
    Response response = await _dio.put(
      path,
      data: FormData.fromMap(params),
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = await toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return put(path, params: params, tag: tag);
    }
    return result;
  }

  /// DELETE请求
  Future<Result> delete(
    String path, {
    Map<String, dynamic> params = const {},
    String tag,
  }) async {
    if (await _needLogin(path)) {
      eventBus.sendEvent(EventBusType.loginInvalid);
      return Result(msg: '请先登录');
    }
    Response response = await _dio.delete(
      path,
      queryParameters: params,
      cancelToken: _getCancelTokenByTag(tag),
    );
    var result = await toResult(response);
    // null表示需要重新请求接口
    if (result == null) {
      return delete(path, params: params, tag: tag);
    }
    return result;
  }

  /// 通过tag获取CancelToken
  CancelToken _getCancelTokenByTag(String tag) {
    CancelToken cancelToken;
    if (tag?.isNotEmpty == true) {
      cancelToken = _cancelTokens[tag];
      if (cancelToken == null) {
        cancelToken = CancelToken();
        _cancelTokens[tag] = cancelToken;
      }
    }
    return cancelToken;
  }

  /// 检查登录状态
  Future<bool> _needLogin(String api) async {
    print('检查接口是否需要登录--$api');
    if (apisWithoutToken.contains(api)) return false;
    if (_token.isNotEmpty) return false;
    final rt = await _refreshToken;
    if (rt.isNotEmpty) return false;
    print('需要登录');
    return true;
  }

  // null表示需要重新请求接口
  Future<Result> toResult(Response response) async {
    if (response.data == null || response.data is! String)
      return const Result();
    var resp = json.decode(response.data);
    final code = resp['code'];
    if (code == null) return const Result();
    var result = Result(
      code: code,
      msg: errorCodes[code] ?? '未知错误',
      data: resp["data"],
    );
    // 需要重新登录
    if (result.code == 10000 ||
        (result.code == 10001 && (await _refreshToken).isEmpty)) {
      eventBus.sendEvent(EventBusType.loginInvalid);
      return result;
    }
    // token失效，refreshToken存在，需要重新请求
    if (result.code == 10001) {
      _token = '';
      return null;
    }
    return result;
  }
}

/// 不需要检查token的接口
const apisWithoutToken = [
  '/',
  '/login',
  '/get_vf_code',
  '/register',
  '/reset_pwd',
  '/forum',
  '/forum/get_posts',
  '/forum/get_floors',
  '/forum/get_inner_floors',
  '/forum/get_post_labels'
];

/// 服务器返回的错误码对应的文字
const errorCodes = {
  /// 失败
  -1: '操作失败',

  /// 成功
  0: '操作成功',

  /// refreshToken失效
  100: 'token失效，请重新登录',

  /// token失效
  101: 'token失效，请重新登录',

  /// 参数错误
  110: '参数错误',

  /// 没有收到文件数据
  111: '没有收到文件数据',

  /// 账号不能为空
  10010: '账号不能为空',

  /// 账号不存在
  10011: '账号不存在',

  /// 账号已存在
  10012: '账号已存在',

  /// 密码不能为空
  10013: '密码不能为空',

  /// 密码不正确
  10014: '密码不正确',

  /// 邮箱不能为空
  10015: '邮箱不能为空',

  /// 验证码不能为空
  10016: '验证码不能为空',

  /// 验证码不正确
  10017: '验证码不正确',

  /// 昵称已存在
  10018: '昵称已存在',

  /// 用户不存在
  10019: '用户不存在'
};
