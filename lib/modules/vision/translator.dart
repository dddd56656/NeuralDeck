import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// [Translator] 封装了 Google ML Kit 的离线翻译能力。
/// 谷歌标准建议：复用翻译器实例，而不是频繁创建/销毁。
class Translator {
  Translator._internal();
  static final Translator instance = Translator._internal();

  final _modelManager = OnDeviceTranslatorModelManager();

  // 缓存翻译器实例，避免内存抖动
  OnDeviceTranslator? _activeTranslator;
  TranslateLanguage? _currentSourceLang;

  /// 核心翻译接口
  Future<String> translate(String input, {String sourceLangCode = 'en'}) async {
    if (input.trim().isEmpty) return "";

    // 1. 语言映射逻辑
    final source = _mapLanguage(sourceLangCode);
    final target = TranslateLanguage.chinese;

    try {
      // 2. 模型下载管理（必须在创建翻译器前确认模型存在）
      await _ensureModelDownloaded(source);

      // 3. 获取或更新翻译器单例 (修复：避免重复实例化的核心逻辑)
      final translator = _getTranslator(source, target);

      // 4. 执行翻译
      return await translator.translateText(input);
    } catch (e) {
      print("Google ML Kit Error: $e");
      return "翻译出错: $e";
    }
  }

  /// 辅助方法：确保模型已下载
  Future<void> _ensureModelDownloaded(TranslateLanguage lang) async {
    // 1. 将枚举转换为插件需要的 String (BCP-47 格式)
    // 如果 lang.bcp47Code 报错，请改用 lang.name 或下面的手动映射
    final String langCode = _getBCP47Code(lang);

    final isDownloaded = await _modelManager.isModelDownloaded(langCode);

    if (!isDownloaded) {
      print("正在下载离线模型: $langCode...");
      // 这里也需要传入 String
      await _modelManager.downloadModel(langCode);
    }
  }

  /// 辅助方法：将枚举安全映射为 String
  /// 适配：The argument type 'TranslateLanguage' can't be assigned to 'String'
  String _getBCP47Code(TranslateLanguage lang) {
    // 谷歌 ML Kit 常见的语言代码映射
    switch (lang) {
      case TranslateLanguage.english:
        return 'en';
      case TranslateLanguage.japanese:
        return 'ja';
      case TranslateLanguage.chinese:
        return 'zh';
      default:
        return 'en';
    }
  }

  /// 核心优化：复用 Translator 实例
  OnDeviceTranslator _getTranslator(
    TranslateLanguage source,
    TranslateLanguage target,
  ) {
    if (_activeTranslator != null && _currentSourceLang == source) {
      return _activeTranslator!;
    }

    // 如果语言变了，关闭旧的，开个新的
    _activeTranslator?.close();
    _currentSourceLang = source;
    _activeTranslator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    return _activeTranslator!;
  }

  TranslateLanguage _mapLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
        return TranslateLanguage.japanese;
      case 'en':
        return TranslateLanguage.english;
      default:
        return TranslateLanguage.english;
    }
  }

  /// 当整个服务不再需要时调用（例如退出应用）
  void dispose() {
    _activeTranslator?.close();
  }
}
