# 🍒 Cherry Note

<div align="center">

![Cherry Note Logo](assets/icons/app_icon.svg)

**专业的跨平台云端笔记应用**

[![Build Status](https://github.com/your-org/cherry-note/workflows/Build%20and%20Release/badge.svg)](https://github.com/your-org/cherry-note/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20macOS-lightgrey.svg)](https://github.com/your-org/cherry-note)

[English](README_EN.md) | 简体中文

</div>

## ✨ 特性

- 📝 **Markdown 编辑器** - 实时语法高亮和预览，支持分屏模式
- ☁️ **云端同步** - 支持 S3 兼容对象存储，多设备无缝同步
- 📁 **多级文件夹** - 无限层级的文件夹结构，拖拽重组
- 🏷️ **智能标签** - 灵活的标签系统，支持多条件过滤
- 🔍 **强大搜索** - 全文搜索，快速定位内容
- ⚡ **便签功能** - 快速创建临时笔记
- 📤 **导入导出** - 支持 Markdown 和 ZIP 格式
- 🎨 **美观界面** - 现代化三栏布局，深色/浅色主题
- 📱 **跨平台** - Android、Windows、macOS 全平台支持
- 🔒 **隐私安全** - 数据加密，开源透明

## 📸 截图

<div align="center">
  <img src="docs/screenshots/main-interface.png" alt="主界面" width="800">
  <p><em>三栏布局 - 文件夹树、笔记列表、编辑预览区</em></p>
</div>

<div align="center">
  <img src="docs/screenshots/markdown-editor.png" alt="Markdown编辑器" width="400">
  <img src="docs/screenshots/tag-filter.png" alt="标签过滤" width="400">
  <p><em>Markdown 实时编辑预览 & 智能标签过滤</em></p>
</div>

## 🚀 快速开始

### 下载安装

#### 📱 Android
- [Google Play Store](https://play.google.com/store/apps/details?id=space.todo8.cherry_note)
- [直接下载 APK](https://github.com/your-org/cherry-note/releases/latest)

#### 🖥️ Windows
- [Microsoft Store](https://www.microsoft.com/store/apps/cherry-note)
- [直接下载](https://github.com/your-org/cherry-note/releases/latest)

#### 🍎 macOS
- [Mac App Store](https://apps.apple.com/app/cherry-note)
- [直接下载 DMG](https://github.com/your-org/cherry-note/releases/latest)

### 首次配置

1. **安装应用**后启动 Cherry Note
2. **配置 S3 存储**：
   - 点击设置 → S3 配置
   - 填入端点 URL、访问密钥等信息
   - 点击"测试连接"验证配置
3. **开始使用**：
   - 创建第一个文件夹
   - 新建笔记开始写作
   - 享受云端同步的便利

### S3 兼容服务

Cherry Note 支持所有 S3 兼容的对象存储服务：

- **Amazon S3** - AWS 官方服务
- **阿里云 OSS** - 阿里云对象存储
- **腾讯云 COS** - 腾讯云对象存储
- **MinIO** - 开源自建服务
- **Backblaze B2** - 经济实惠的云存储
- 其他 S3 兼容服务

## 📖 使用指南

### 基本操作

#### 创建和编辑笔记
```
1. 右键点击文件夹 → 新建笔记
2. 输入笔记标题
3. 使用 Markdown 语法编写内容
4. 内容自动保存，实时同步到云端
```

#### 组织笔记
```
📁 工作笔记/
├── 📁 项目A/
│   ├── 📝 需求分析.md
│   └── 📝 技术方案.md
├── 📁 项目B/
│   └── 📝 进度记录.md
└── 📝 会议记录.md
```

#### 标签管理
```
#工作 #重要 #待办 #学习
```
- 在编辑器顶部添加标签
- 左侧标签区域点击过滤
- 支持多标签 AND/OR 逻辑过滤

### 高级功能

#### Markdown 语法支持
- **标题**: `# ## ###`
- **强调**: `**粗体**` `*斜体*`
- **列表**: `- 无序` `1. 有序`
- **链接**: `[文本](URL)`
- **图片**: `![描述](URL)`
- **代码**: `` `代码` `` 和 ``` 代码块 ```
- **表格**: 使用 `|` 分隔
- **公式**: `$数学公式$`

#### 快捷键
- `Ctrl/Cmd + N` - 新建笔记
- `Ctrl/Cmd + S` - 保存笔记
- `Ctrl/Cmd + F` - 搜索
- `Ctrl/Cmd + B` - 粗体
- `Ctrl/Cmd + I` - 斜体
- `F11` - 全屏模式

## 🛠️ 开发

### 环境要求

- Flutter SDK 3.16.0+
- Dart SDK 3.0.0+
- Android Studio / VS Code
- Git

### 本地开发

```bash
# 克隆项目
git clone https://github.com/your-org/cherry-note.git
cd cherry-note

# 安装依赖
flutter pub get

# 生成代码
flutter packages pub run build_runner build --delete-conflicting-outputs

# 运行应用
flutter run
```

### 项目结构

```
lib/
├── core/                 # 核心功能
│   ├── di/              # 依赖注入
│   ├── error/           # 错误处理
│   ├── services/        # 核心服务
│   └── theme/           # 主题配置
├── features/            # 功能模块
│   ├── notes/           # 笔记管理
│   ├── folders/         # 文件夹管理
│   ├── sync/            # 同步功能
│   └── tags/            # 标签系统
└── shared/              # 共享组件
    ├── utils/           # 工具函数
    └── widgets/         # 通用组件
```

### 构建发布

```bash
# Android
./scripts/build_android.sh production release

# Windows
./scripts/build_windows.sh release

# macOS
./scripts/build_macos.sh release

# 所有平台
./scripts/build_all.sh release
```

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行测试并生成覆盖率报告
flutter test --coverage

# 运行集成测试
flutter test integration_test/
```

测试覆盖率目标：
- 单元测试覆盖率 > 85%
- 集成测试覆盖主要功能
- 端到端测试验证用户流程

## 📚 文档

- [用户手册](docs/user-manual.md) - 详细的使用指南
- [开发者文档](docs/developer-guide.md) - 开发和贡献指南
- [API 参考](docs/API.md) - 完整的 API 文档
- [常见问题](docs/FAQ.md) - 常见问题解答
- [更新日志](docs/CHANGELOG.md) - 版本更新记录

## 🤝 贡献

我们欢迎所有形式的贡献！

### 如何贡献

1. **Fork** 本项目
2. **创建**功能分支 (`git checkout -b feature/AmazingFeature`)
3. **提交**更改 (`git commit -m 'Add some AmazingFeature'`)
4. **推送**到分支 (`git push origin feature/AmazingFeature`)
5. **创建** Pull Request

### 贡献类型

- 🐛 Bug 修复
- ✨ 新功能开发
- 📚 文档改进
- 🎨 UI/UX 优化
- 🌍 多语言翻译
- 🧪 测试用例
- ⚡ 性能优化

### 开发规范

- 遵循 [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- 使用 [Conventional Commits](https://www.conventionalcommits.org/) 提交格式
- 为新功能添加测试用例
- 更新相关文档

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

感谢所有为 Cherry Note 做出贡献的开发者和用户！

特别感谢：
- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [BLoC](https://bloclibrary.dev/) - 强大的状态管理
- [GetIt](https://pub.dev/packages/get_it) - 依赖注入容器
- 所有开源库的维护者们

## 📞 联系我们

- **官网**: https://cherrynote.app
- **邮箱**: support@cherrynote.app
- **GitHub**: https://github.com/your-org/cherry-note
- **问题反馈**: [GitHub Issues](https://github.com/your-org/cherry-note/issues)

---

<div align="center">

**如果 Cherry Note 对您有帮助，请给我们一个 ⭐ Star！**

Made with ❤️ by Cherry Note Team

</div>