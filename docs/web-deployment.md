# Cherry Note Web 部署指南

本文档详细介绍如何部署 Cherry Note 的 Web 版本到各种托管平台。

## 构建 Web 版本

### 基本构建
```bash
# 启用 Web 支持
flutter config --enable-web

# 安装依赖
flutter pub get

# 构建生产版本
flutter build web --release
```

### 优化构建
```bash
# 使用 CanvasKit 渲染器（推荐）
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_USE_SKIA=true

# 使用自定义 CanvasKit URL
flutter build web --release \
  --web-renderer canvaskit \
  --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.38.0/bin/
```

### 使用构建脚本
```bash
# 使用项目提供的构建脚本
./scripts/build_web.sh release
```

## 部署平台

### 1. GitHub Pages

#### 自动部署（推荐）
项目已配置 GitHub Actions 自动部署：

1. 推送代码到 `main` 分支
2. GitHub Actions 自动构建并部署到 GitHub Pages
3. 访问 `https://your-username.github.io/cherry-note`

#### 手动部署
```bash
# 构建项目
flutter build web --release

# 部署到 gh-pages 分支
git checkout --orphan gh-pages
git rm -rf .
cp -r build/web/* .
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

### 2. Netlify

#### 通过 Git 部署
1. 连接 GitHub 仓库到 Netlify
2. 设置构建命令：`flutter build web --release`
3. 设置发布目录：`build/web`
4. 部署完成后获得 `.netlify.app` 域名

#### 手动部署
```bash
# 构建项目
flutter build web --release

# 安装 Netlify CLI
npm install -g netlify-cli

# 部署
netlify deploy --prod --dir=build/web
```

### 3. Vercel

#### 通过 Git 部署
1. 导入 GitHub 仓库到 Vercel
2. 设置框架预设为 "Other"
3. 设置构建命令：`flutter build web --release`
4. 设置输出目录：`build/web`

#### 使用 vercel.json 配置
```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "flutter pub get"
}
```

### 4. Firebase Hosting

#### 初始化 Firebase
```bash
# 安装 Firebase CLI
npm install -g firebase-tools

# 登录 Firebase
firebase login

# 初始化项目
firebase init hosting
```

#### 配置 firebase.json
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

#### 部署
```bash
# 构建项目
flutter build web --release

# 部署到 Firebase
firebase deploy
```

### 5. AWS S3 + CloudFront

#### 创建 S3 存储桶
```bash
# 创建存储桶
aws s3 mb s3://cherry-note-web

# 配置静态网站托管
aws s3 website s3://cherry-note-web \
  --index-document index.html \
  --error-document index.html
```

#### 上传文件
```bash
# 构建项目
flutter build web --release

# 同步到 S3
aws s3 sync build/web/ s3://cherry-note-web \
  --delete \
  --cache-control max-age=31536000
```

#### 配置 CloudFront
1. 创建 CloudFront 分发
2. 设置源为 S3 存储桶
3. 配置缓存行为
4. 设置自定义错误页面

## PWA 配置

### Service Worker
Flutter 自动生成 Service Worker，支持：
- 应用缓存
- 离线功能
- 后台同步

### 安装提示
在支持的浏览器中，用户可以：
1. 点击地址栏的安装图标
2. 通过浏览器菜单安装
3. 在移动设备上添加到主屏幕

### 推送通知
```javascript
// 在 web/index.html 中添加
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/flutter_service_worker.js');
}

if ('Notification' in window) {
  Notification.requestPermission();
}
```

## 性能优化

### 1. 资源优化
```bash
# 启用 tree-shaking
flutter build web --release --tree-shake-icons

# 压缩资源
flutter build web --release --web-renderer canvaskit
```

### 2. 缓存策略
在服务器配置中设置适当的缓存头：
```nginx
# Nginx 配置示例
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location / {
    try_files $uri $uri/ /index.html;
    add_header Cache-Control "no-cache";
}
```

### 3. CDN 配置
- 使用 CDN 加速静态资源
- 配置 GZIP 压缩
- 启用 HTTP/2

## 域名配置

### 自定义域名
1. 在 DNS 提供商处添加 CNAME 记录
2. 在托管平台配置自定义域名
3. 启用 HTTPS（推荐使用 Let's Encrypt）

### HTTPS 配置
PWA 功能需要 HTTPS：
- 大多数托管平台自动提供 HTTPS
- 自建服务器需要配置 SSL 证书

## 监控和分析

### Google Analytics
在 `web/index.html` 中添加：
```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());
  gtag('config', 'GA_MEASUREMENT_ID');
</script>
```

### 错误监控
集成 Sentry 或其他错误监控服务：
```dart
// 在 main.dart 中
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'YOUR_SENTRY_DSN';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

## 故障排除

### 常见问题

#### 1. 白屏问题
- 检查浏览器控制台错误
- 确认所有资源正确加载
- 验证 base href 配置

#### 2. 路由问题
- 配置服务器重写规则
- 确保 SPA 路由正确处理

#### 3. 缓存问题
- 清除浏览器缓存
- 检查 Service Worker 更新
- 验证缓存策略

#### 4. PWA 安装问题
- 确保 HTTPS 连接
- 检查 manifest.json 配置
- 验证 Service Worker 注册

### 调试工具
- Chrome DevTools
- Firefox Developer Tools
- Lighthouse 性能分析
- PWA Builder 验证

## 最佳实践

1. **性能优化**
   - 使用 CanvasKit 渲染器
   - 启用资源压缩
   - 配置适当的缓存策略

2. **SEO 优化**
   - 设置适当的 meta 标签
   - 配置 Open Graph 标签
   - 添加结构化数据

3. **用户体验**
   - 提供离线功能
   - 优化加载速度
   - 支持 PWA 安装

4. **安全性**
   - 启用 HTTPS
   - 配置 CSP 头
   - 定期更新依赖

5. **监控**
   - 设置错误监控
   - 配置性能监控
   - 收集用户反馈

## 如何使用 Web 版本

### 开发环境设置

#### 1. 启用 Web 支持
```bash
# 检查 Flutter 版本（需要 3.16.0+）
flutter --version

# 启用 Web 支持
flutter config --enable-web

# 验证 Web 支持已启用
flutter config
```

#### 2. 安装依赖
```bash
# 进入项目目录
cd cherry-note

# 获取依赖
flutter pub get

# 生成必要的代码（如果需要）
flutter packages pub run build_runner build --delete-conflicting-outputs
```

#### 3. 本地开发运行
```bash
# 在 Chrome 中运行（推荐）
flutter run -d chrome

# 在 Edge 中运行
flutter run -d edge

# 在默认浏览器中运行
flutter run -d web-server --web-port 8080
```

### 构建和测试

#### 1. 开发构建
```bash
# 构建调试版本（用于开发测试）
flutter build web --debug

# 构建 Profile 版本（用于性能测试）
flutter build web --profile
```

#### 2. 生产构建
```bash
# 使用项目构建脚本（推荐）
./scripts/build_web.sh release

# 或者直接使用 Flutter 命令
flutter build web --release --optimization-level=4 --source-maps
```

#### 3. 本地测试构建结果
```bash
# 方法 1：使用 Python HTTP 服务器
cd build/web
python3 -m http.server 8000
# 访问 http://localhost:8000

# 方法 2：使用 Node.js serve
npm install -g serve
serve -s build/web -l 8000

# 方法 3：使用 PHP 内置服务器
cd build/web
php -S localhost:8000
```

### 功能使用指南

#### 1. PWA 安装
用户可以通过以下方式安装 Web 应用：

**桌面浏览器：**
- Chrome/Edge：点击地址栏右侧的安装图标
- Firefox：点击地址栏的"安装"按钮
- Safari：通过"文件" → "添加到程序坞"

**移动浏览器：**
- Chrome/Edge：点击菜单 → "添加到主屏幕"
- Safari：点击分享按钮 → "添加到主屏幕"

#### 2. 文件操作
Web 版本支持以下文件操作：

**导入文件：**
```javascript
// 支持的文件类型
- Markdown 文件 (.md)
- 文本文件 (.txt)
- JSON 文件 (.json)
- ZIP 压缩包 (.zip)
```

**导出功能：**
- 单个笔记导出为 Markdown
- 批量导出为 ZIP 文件
- 设置导出为 JSON 格式

**拖拽操作：**
- 直接拖拽文件到浏览器窗口
- 支持多文件同时拖拽
- 自动识别文件类型

#### 3. 响应式布局
Web 版本会根据屏幕尺寸自动调整：

**桌面模式（≥1024px）：**
- 三栏布局：文件夹树 + 笔记列表 + 编辑器
- 持久化侧边栏
- 完整的工具栏和菜单

**平板模式（768px-1023px）：**
- 可折叠侧边栏
- 优化的触摸操作
- 适中的字体和按钮尺寸

**手机模式（<768px）：**
- 单栏布局，通过导航切换
- 底部导航栏
- 大号触摸按钮

#### 4. 键盘快捷键
Web 版本支持完整的键盘快捷键：

```
Ctrl/Cmd + N    - 新建笔记
Ctrl/Cmd + S    - 保存笔记
Ctrl/Cmd + F    - 搜索
Ctrl/Cmd + B    - 粗体
Ctrl/Cmd + I    - 斜体
Ctrl/Cmd + K    - 插入链接
Ctrl/Cmd + /    - 切换预览
F11             - 全屏模式
Esc             - 退出全屏/关闭对话框
```

### 离线功能

#### 1. Service Worker 缓存
Web 版本自动缓存以下内容：
- 应用程序代码和资源
- 用户创建的笔记内容
- 应用设置和配置

#### 2. 离线使用
当网络不可用时：
- 可以继续查看已缓存的笔记
- 可以创建和编辑笔记
- 修改会在网络恢复时自动同步

#### 3. 同步状态指示
- 在线状态：绿色指示器
- 离线状态：橙色指示器
- 同步中：蓝色旋转指示器
- 同步失败：红色警告指示器

### 浏览器兼容性

#### 支持的浏览器版本
```
Chrome    88+  ✅ 完全支持
Firefox   85+  ✅ 完全支持
Safari    14+  ✅ 完全支持
Edge      88+  ✅ 完全支持
Opera     74+  ✅ 基本支持
```

#### 功能支持检查
应用启动时会自动检查浏览器功能：
- Web Storage API
- File API
- Service Worker
- Push Notifications
- IndexedDB

### 性能优化建议

#### 1. 浏览器设置
- 启用硬件加速
- 允许 JavaScript
- 启用 Cookies 和本地存储
- 定期清理浏览器缓存

#### 2. 网络优化
- 使用稳定的网络连接
- 启用浏览器缓存
- 考虑使用 CDN 加速

#### 3. 设备要求
**最低要求：**
- RAM: 2GB
- 存储: 100MB 可用空间
- 网络: 1Mbps（首次加载）

**推荐配置：**
- RAM: 4GB+
- 存储: 500MB+ 可用空间
- 网络: 5Mbps+

### 故障排除

#### 常见问题解决

**1. 应用无法加载**
```bash
# 检查网络连接
ping google.com

# 清除浏览器缓存
# Chrome: Ctrl+Shift+Delete
# Firefox: Ctrl+Shift+Delete
# Safari: Cmd+Option+E

# 检查浏览器控制台错误
# 按 F12 打开开发者工具
```

**2. 文件上传失败**
- 检查文件大小（限制 100MB）
- 确认文件格式支持
- 检查浏览器权限设置

**3. PWA 安装问题**
- 确保使用 HTTPS 连接
- 检查 manifest.json 配置
- 验证 Service Worker 注册

**4. 同步问题**
- 检查 S3 配置
- 验证网络连接
- 查看错误日志

#### 调试工具使用

**浏览器开发者工具：**
```
F12              - 打开开发者工具
Console 标签     - 查看错误日志
Network 标签     - 检查网络请求
Application 标签 - 查看存储和缓存
Lighthouse 标签  - 性能分析
```

**PWA 调试：**
- Application → Service Workers
- Application → Storage
- Application → Manifest

### 最佳实践

#### 1. 用户体验
- 定期保存工作内容
- 使用浏览器书签收藏应用
- 安装 PWA 版本获得更好体验
- 启用浏览器通知

#### 2. 数据安全
- 定期导出重要笔记
- 配置可靠的 S3 存储
- 使用强密码保护账户
- 定期检查同步状态

#### 3. 性能优化
- 关闭不必要的浏览器标签
- 定期清理浏览器缓存
- 使用最新版本的浏览器
- 避免同时运行多个重型应用

通过遵循这些指南，您可以成功部署和使用 Cherry Note 的 Web 版本，为用户提供优秀的在线笔记体验。