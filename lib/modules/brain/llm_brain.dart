import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/services/local_db.dart';
import 'brain_interface.dart';

/// [LLMBrain] 实现混合动力推理：
/// 1. 优先从本地 SQLite 数据库检索缓存的描述。
/// 2. 若无缓存，则请求云端 DeepSeek API 并将结果存入数据库。
class LLMBrain implements BrainInterface {
  // TODO: 替换为你真实的 DeepSeek API Key
  final String _apiKey = "sk-b25f566b44a340c190322559b2861a32";
  final String _apiUrl = "https://api.deepseek.com/v1/chat/completions";

  @override
  Future<void> init() async {
    print("🧠 [Brain] 混合动力引擎初始化完成，链接数据库中...");
  }

  @override
  Stream<String> generateLoreStream(String inputTags) async* {
    // 1. 尝试从本地数据库获取缓存
    final cachedLore = await LocalDB.instance.getCachedLore(inputTags);

    if (cachedLore != null) {
      print("📜 [Brain] 命中本地记忆，直接提取历史记录...");
      yield* _simulateTypingEffect(cachedLore);
      return;
    }

    // 2. 本地未命中，调用云端 DeepSeek
    print("🌐 [Brain] 本地无记录，正在连接云端 DeepSeek...");
    yield " [正在建立神经链路...] ";

    try {
      final response = await _fetchFromDeepSeek(inputTags);

      // 3. 存储到本地数据库，实现“知识沉淀”
      await LocalDB.instance.saveLoreToCache(inputTags, response);

      yield* _simulateTypingEffect(response);
    } catch (e) {
      print("❌ [Brain] 云端请求失败: $e");
      yield " [链路异常] 无法解析当前物品。原因: 网络抖动。";
    }
  }

  /// 模拟打字机效果，维持赛博朋克 UI 体验
  Stream<String> _simulateTypingEffect(String text) async* {
    for (var i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      yield text[i];
    }
  }

  /// 调用 DeepSeek API
  Future<String> _fetchFromDeepSeek(String tags) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            "model": "deepseek-chat",
            "messages": [
              {
                "role": "system",
                "content":
                    "你是一个2077年的赛博朋克装备扫描仪。请根据输入的标签（英文），用中文写一段简短、酷炫且具有世界观背景的物品描述。不要超过100字。语气要冰冷、硬核。",
              },
              {"role": "user", "content": "Tags: $tags"},
            ],
            "temperature": 0.7,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception("API Error: ${response.statusCode}");
    }
  }

  @override
  Future<Map<String, dynamic>> analyzeTarget(String inputTags) async {
    // 基础认知分析，暂返回空数据
    return {};
  }

  @override
  void dispose() {
    print("🧹 [Brain] 资源已释放");
  }
}
