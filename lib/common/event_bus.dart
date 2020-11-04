import 'dart:async';

EventBus get eventBus => EventBus();

typedef void EventBusCallback(arg);

/// 监听、触发全局事件
class EventBus {
  static EventBus _singleton;

  // 事件分发StreamController
  final StreamController<_Event> _controller;

  EventBus._init() : _controller = StreamController<_Event>() {
    _controller.stream.listen((e) {
      callbacks.where((c) => c.type == e.type).forEach((c) => c.cb(e.arg));
    });
  }

  factory EventBus() {
    if (_singleton == null) _singleton = EventBus._init();
    return _singleton;
  }

  // 监听的回调方法
  final callbacks = List<_Callback>();

  /// 监听事件
  void on(String type, EventBusCallback cb, [tag = 'all']) {
    assert(type != null && cb != null, 'EventBug监听必须传入type和cb');
    callbacks.add(_Callback(type, tag, cb));
  }

  /// 取消监听
  void off({String tag, EventBusCallback cb}) {
    assert(tag != null || cb != null, '取消EventBug监听必须传入tag或者cb');
    if (tag != null) callbacks.removeWhere((c) => c.tag == tag);
    if (cb != null) callbacks.removeWhere((c) => c.cb == cb);
  }

  /// 发送事件
  void sendEvent(String type, [dynamic arg]) {
    assert(type != null, 'EventBug发送事件必须传入type');
    _controller.add(_Event(type, arg));
  }
}

class _Event {
  final String type;
  final dynamic arg;

  _Event(this.type, [this.arg]);
}

class _Callback {
  final String type;
  final String tag;
  final EventBusCallback cb;

  _Callback(this.type, this.tag, this.cb);
}