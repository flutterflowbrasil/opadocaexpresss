import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'onesignal_bridge.dart';

@JS('__opadocaPush.init')
external JSPromise _init(JSString appId);

@JS('__opadocaPush.login')
external JSPromise _login(JSString userId);

@JS('__opadocaPush.logout')
external JSPromise _logout();

@JS('__opadocaPush.requestPermission')
external JSPromise _requestPermission();

@JS('__opadocaPush.subscriptionId')
external JSString? _subscriptionId();

@JS('__opadocaPush.onSubscriptionChange')
external void _onSubscriptionChange(JSFunction callback);

@JS('__opadocaPush.onNotificationClick')
external void _onNotificationClick(JSFunction callback);

class WebOneSignalBridge implements OneSignalBridge {
  bool _initialized = false;
  bool _subscriptionObserver = false;
  bool _clickListener = false;

  @override
  Future<void> initialize(String appId) async {
    if (_initialized || appId.isEmpty) return;
    try {
      await _init(appId.toJS).toDart;
      _initialized = true;
    } catch (e) {
      debugPrint('[OneSignal] web init: $e');
    }
  }

  @override
  Future<void> login(String userId) async {
    try {
      await _login(userId.toJS).toDart;
    } catch (e) {
      debugPrint('[OneSignal] web login: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _logout().toDart;
    } catch (e) {
      debugPrint('[OneSignal] web logout: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      final result = await _requestPermission().toDart;
      return result?.dartify() == true;
    } catch (e) {
      debugPrint('[OneSignal] web permission: $e');
      return false;
    }
  }

  @override
  Future<String?> subscriptionId() async {
    try {
      final id = _subscriptionId()?.toDart;
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (e) {
      debugPrint('[OneSignal] web subscriptionId: $e');
      return null;
    }
  }

  @override
  void addSubscriptionObserver(void Function(String id) onChanged) {
    if (_subscriptionObserver) return;
    _subscriptionObserver = true;
    try {
      _onSubscriptionChange(((JSString id) {
        final value = id.toDart;
        if (value.isNotEmpty) onChanged(value);
      }).toJS);
    } catch (e) {
      debugPrint('[OneSignal] web observer: $e');
    }
  }

  @override
  void addClickListener(void Function(Map<String, dynamic> data) onClick) {
    if (_clickListener) return;
    _clickListener = true;
    try {
      _onNotificationClick(((JSString json) {
        try {
          final decoded = jsonDecode(json.toDart);
          if (decoded is Map<String, dynamic>) {
            onClick(decoded);
          } else if (decoded is Map) {
            onClick(Map<String, dynamic>.from(decoded));
          } else {
            onClick(const {});
          }
        } catch (_) {
          onClick(const {});
        }
      }).toJS);
    } catch (e) {
      debugPrint('[OneSignal] web click listener: $e');
    }
  }
}

OneSignalBridge createOneSignalBridgeImpl() => WebOneSignalBridge();
