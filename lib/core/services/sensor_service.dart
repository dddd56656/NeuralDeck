import 'dart:async';
import 'package:flutter/services.dart'; // 用于 HapticFeedback
import 'package:sensors_plus/sensors_plus.dart'; // [新增引用]

// 传感器服务
class SensorService {
  // 单例模式
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  // [实现] 监听设备倾斜 (陀螺仪)
  // 返回陀螺仪事件流，UI 组件可以监听这个流来做视差动画
  Stream<GyroscopeEvent> get gyroscopeStream {
    return gyroscopeEvents;
  }

  // [实现] 触发震动反馈 (Haptics)
  Future<void> vibrate(String intensity) async {
    switch (intensity) {
      case 'light':
        await HapticFeedback.lightImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        await HapticFeedback.heavyImpact();
        break;
      case 'success':
        // 只有 Android 支持 selectionClick，iOS 会回退到 light
        await HapticFeedback.selectionClick();
        break;
      default:
        await HapticFeedback.lightImpact();
    }
  }
}
