# 资源文件目录

此目录包含 NeuralDeck 应用所需的所有离线资源文件。

## 目录结构

### models/
存放 AI 模型文件：
- `llama-3-8b-instruct.Q4_K_M.gguf` - Llama-3 量化模型
- `translation_model.bin` - 离线翻译模型
- 其他自定义模型文件

### live2d/
存放 Live2D 虚拟角色模型：
- `haru/` - Haru 角色模型文件
- `wanko/` - Wanko 角色模型文件
- 其他 Live2D 角色

### sounds/
存放音效文件：
- `scan.wav` - 扫描音效
- `error.wav` - 错误提示音效
- `success.wav` - 成功音效
- `cyber_ambient.wav` - 环境背景音

### images/
存放 UI 图像资源：
- `borders/` - 卡片边框图像
- `icons/` - 应用图标
- `backgrounds/` - 背景图像
- `ui_elements/` - UI 组件图像

## 使用说明

1. **模型文件**：由于文件大小限制，模型文件不包含在 Git 仓库中。
2. **下载模型**：请从官方渠道下载所需模型并放置到对应目录。
3. **文件命名**：保持原始文件名以确保代码正确引用。
4. **版权注意**：确保您拥有使用所有资源文件的合法权利。

## 模型下载链接

- Llama-3 GGUF 模型：https://huggingface.co/models
- ML Kit 翻译模型：通过 Google ML Kit 自动下载
- Live2D 模型：从官方商店购买或使用免费模型

## 注意事项

- 首次运行应用前，请确保所有必需模型文件已就位
- 模型文件较大，建议在 Wi-Fi 环境下下载
- 定期检查模型更新以获得更好的性能