import 'package:flutter/material.dart';

// [修改] 简化版 Live2D 控制器 (模拟)
// 真正的 Cubism SDK 集成过于复杂，这里我们用 ValueNotifier 管理状态
class Live2dController {
  // 当前表情状态，UI 可以监听这个变化
  final ValueNotifier<String> currentExpression = ValueNotifier("idle");

  // [实现] 模拟加载模型
  Future<void> loadModel(String modelPath) async {
    print("Live2D System: Loading model from $modelPath...");
    await Future.delayed(const Duration(milliseconds: 500));
    print("Live2D System: Model Online.");
  }

  // [实现] 设置表情
  void setExpression(String expressionName) {
    print("Live2D Expression Switch: $expressionName");
    currentExpression.value = expressionName;

    // 模拟动作结束后自动恢复待机状态
    if (expressionName != 'idle') {
      Future.delayed(const Duration(seconds: 3), () {
        currentExpression.value = 'idle';
      });
    }
  }

  // [实现] 每一帧的渲染回调 (暂时留空，不需要每一帧都手动处理)
  void onRender() {
    // 实际项目中这里会调用 _cubismModel.update()
  }

  void dispose() {
    currentExpression.dispose();
  }
}
