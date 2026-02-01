import 'dart:async';
import 'dart:math';
import 'brain_interface.dart';

/// [LLMBrain]
/// 离线专家系统 (Expert System AI) - 中文版
/// 100% 离线，无崩溃风险。
class LLMBrain implements BrainInterface {
  // 离线中文知识库 (Cyberpunk Style)
  // 通过关键词匹配，模拟 AI 识别能力
  final Map<String, String> _knowledgeBase = {
    '书': '检测到高密度信息载体。推测为旧时代“书籍”，蕴含着未被数字化的原始知识。建议扫描归档。',
    '本': '检测到纸质存储介质。数据完整性良好，内容需进一步光学解析。',
    '水': '识别为液态H2O。在荒原上属于一级生存资源。辐射指数：低（可饮用）。',
    '瓶': '识别为液态存储容器。工业级封装，密封性良好。',
    '杯': '识别为民用级饮水器具。表面检测到微量生物残留。',
    '键盘': '发现旧式输入设备。机械结构完整，可能是黑客遗留的物理接口。',
    '鼠标': '发现光电定位设备。连接协议：未知。',
    '电脑': '检测到高算力计算节点。尝试接入... 防火墙等级：高。',
    '屏幕': '识别为光电显示终端。像素点排列规则，属于标准的视觉输出接口。',
    '显示器': '识别为视觉输出矩阵。分辨率解析中...',
    '手机': '检测到便携式通信终端。信号加密等级：军用级。',
    '药': '扫描到化学合成物。医疗用途。建议收容以备不时之需。',
    '卡': '检测到身份/凭证磁卡。磁条信息已读取，正在暴力破解权限...',
    '笔': '识别为物理书写工具。墨水残留量：45%。',
    '眼镜': '发现视觉辅助设备。镜片折射率正常。',
    '耳机': '识别为音频接收装置。降噪模块在线。',
    '鞋': '识别为单兵行军装备。磨损度：15%。',
    '包': '检测到战术收纳单元。内部可能有未识别的物资。',
    '猫': '警报：检测到碳基生物（Felis catus）。威胁等级：极高（精神控制风险）。',
    '狗': '检测到碳基生物（Canis lupus）。忠诚度判定中...',
  };

  // 通用备用模板 (随机调用)
  final List<String> _fallbackTemplates = [
    "解析完毕。目标物质结构稳定，检测到微量旧时代辐射残留。推测为大崩坏前的工业制品。",
    "警告：扫描到未知的数据签名。该物体表面附着着微弱的模因污染，建议谨慎接入。",
    "数据库匹配成功。稀有度评级：普通。但在特定维度的黑客手中，它可能成为关键触媒。",
    "目标分析：非生物体。内部结构呈现出一种奇异的分形美感，似乎蕴含着某种未被发现的物理定律。",
    "系统提示：该物品未在联邦数据库注册。已自动标记为“黑市物资”。",
    "扫描完成。物品表面有磨损痕迹，推测曾在夜之城被频繁使用。",
  ];

  @override
  Future<void> init() async {
    print("🧠 Offline Neural Engine (CN): ONLINE.");
  }

  @override
  Map<String, double> analyzeStats(String text) {
    // 确定性随机：同一个物体每次扫出来的属性都一样
    int seed = text.hashCode;
    Random rng = Random(seed);
    double complexity = (text.length / 50).clamp(0.2, 0.9);

    return {
      "ATK": (rng.nextDouble() * 0.8 + 0.1),
      "DEF": (rng.nextDouble() * 0.8 + 0.1),
      "SPD": (rng.nextDouble() * 0.8 + 0.1),
      "MAG": (rng.nextDouble() * 0.6 + complexity * 0.4).clamp(0.0, 1.0),
      "LUCK": rng.nextDouble(),
    };
  }

  @override
  Stream<String> generateLore(String text, String translatedText) async* {
    // 1. 模拟“思考”延迟 (打字机效果)
    String loading =
        "正在检索本地数据库... [HASH_${text.hashCode.toRadixString(16).toUpperCase()}]\n";
    for (var char in loading.split('')) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield char;
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. 核心逻辑：关键词匹配
    String result = "";
    bool foundKeyword = false;

    // 优先匹配翻译后的中文文本
    for (var key in _knowledgeBase.keys) {
      if (translatedText.contains(key) || text.contains(key)) {
        result = _knowledgeBase[key]!;
        foundKeyword = true;
        break;
      }
    }

    // 3. 没匹配到，使用通用赛博风模板
    if (!foundKeyword) {
      int seed = text.hashCode;
      result = _fallbackTemplates[seed % _fallbackTemplates.length];
    }

    // 4. 组装最终文案
    String finalOutput = "\n>> 目标识别：$translatedText\n>> 分析报告：$result";

    // 5. 输出流
    for (var char in finalOutput.split('')) {
      await Future.delayed(const Duration(milliseconds: 30));
      yield char;
    }
  }

  @override
  void dispose() {}
}
