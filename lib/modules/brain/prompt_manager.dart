// Prompt 管理器
class PromptManager {
  // [实现] 获取提示词模板
  String getPromptTemplate(String type) {
    switch (type) {
      case 'lore_generation':
        return """
你是一个来自 2077 年的资深数据黑客。
请分析以下扫描到的目标数据，并用冷酷、科技感十足的口吻生成一段背景介绍。
目标数据: {{DATA}}
要求：包含“威胁等级”、“稀有度”和“历史来源”。字数控制在 100 字以内。
""";

      case 'card_rating':
        return """
作为 NeuralDeck 系统的核心 AI，请对该物体进行数值评估。
输出格式 JSON: {"ATK": 0-1.0, "DEF": 0-1.0, "SPD": 0-1.0, "MAG": 0-1.0, "LUCK": 0-1.0}
""";

      default:
        return "System Override: Analyze {{DATA}}.";
    }
  }
}
