import 'package:flutter_tts/flutter_tts.dart'; // [新增引用]

// 文本转语音服务
class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  // [新增] 持有 FlutterTts 实例
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // [修改] 初始化方法
  Future<void> init() async {
    if (_isInitialized) return;

    // 设置语言，这里默认用中文，你可以改为 'en-US'
    await _flutterTts.setLanguage("zh-CN");

    // 设置语速和音调，符合赛博朋克AI的冷淡感
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _isInitialized = true;
    print("TTS Service Online.");
  }

  // [修改] 朗读方法
  Future<void> speak(String text) async {
    if (!_isInitialized) await init(); // 确保已初始化

    // 停止上一次的朗读，避免重叠
    await _flutterTts.stop();

    print("AI Speaking: $text");
    await _flutterTts.speak(text);
  }

  // [修改] 停止方法
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
