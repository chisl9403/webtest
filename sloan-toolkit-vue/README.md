# 🛠️ Sloan 的工具集# Sloan 的工具集



基于 Vue 3 + TypeScript + Vite 构建的现代化插件系统，提供天气查询、股票信息、日志分析等实用工具。基于 Vue 3 + TypeScript + Vite 构建的插件化工具集系统。



[![Vue 3](https://img.shields.io/badge/Vue-3.4-42b883?logo=vue.js)](https://vuejs.org/)## ✨ 功能特性

[![TypeScript](https://img.shields.io/badge/TypeScript-5.6-3178c6?logo=typescript)](https://www.typescriptlang.org/)

[![Vite](https://img.shields.io/badge/Vite-7.1-646cff?logo=vite)](https://vitejs.dev/)- 🌤️ **天气查询** - 支持城市搜索、收藏和历史记录

[![Element Plus](https://img.shields.io/badge/Element_Plus-2.5-409eff)](https://element-plus.org/)- 📊 **日志分析** - PM:INFO 日志文件分析和可视化

- 🔌 **插件系统** - 模块化插件架构，易于扩展

## ✨ 功能特性- 🎨 **现代 UI** - Element Plus 组件库，响应式设计



### 📡 信息插件## 🚀 快速开始

- 🌤️ **天气查询** - 全球城市天气信息，支持中英文搜索

  - 快速城市选择### 1. 配置 API 密钥

  - 城市收藏功能```bash

  - 搜索历史记录# 复制配置模板

  - 详细天气数据（温度、湿度、风速、气压等）cp config.example.json config.json



- 📈 **股票信息** - 实时股市行情展示# 编辑 config.json，添加你的天气 API 密钥

  - 🔥 涨幅榜 TOP5（东方财富API）```

  - 📊 龙虎榜 TOP5（资金净流入）

  - 自动交易日期计算（排除周末）### 2. 安装依赖

  - 实时数据刷新```bash

npm install

### 📊 日志分析插件```

- **PM:INFO 日志分析** - 专业的日志文件可视化工具

  - 电流趋势分析（自动单位转换：μA/mA/A）### 3. 启动后端服务器（新终端窗口）

  - 温度监控曲线```bash

  - 电压波动图表python3 server.py

  - 充电状态时序图```

  - 数据统计分析

  - 图表交互功能（缩放、平移、重置、全屏）### 4. 启动前端开发服务器

  - 数据导出（CSV格式）```bash

npm run dev

## 🚀 快速开始```



### 📋 前置要求访问：http://localhost:3000



- Node.js >= 16.x### 构建生产版本

- Python >= 3.9```bash

- npm 或 yarnnpm run build

```

### 1️⃣ 克隆项目

### 预览生产版本

```bash```bash

git clone https://github.com/chisl9403/webtest.gitnpm run preview

cd webtest/sloan-toolkit-vue```

```

## 📦 技术栈

### 2️⃣ 配置文件

- **框架**: Vue 3.4+ (Composition API)

```bash- **构建工具**: Vite 7.1+

# 复制配置模板- **UI 组件库**: Element Plus 2.5+

cp config.example.json config.json- **状态管理**: Pinia 2.1+

```- **路由**: Vue Router 4.3+

- **语言**: TypeScript

编辑 `config.json`，添加天气 API 密钥：- **样式**: SCSS



```json## 📁 项目结构

{

  "apiKey": "your_openweathermap_api_key_here",```

  "plugins": {src/

    "info": {├── components/      # 全局组件

      "enabled": true,├── plugins/        # 插件目录

      "autoLoad": true,│   ├── weather/    # 天气插件

      "defaultCity": "Beijing"│   └── log-analyzer/ # 日志分析插件

    },├── views/          # 页面视图

    "logAnalyzer": {├── router/         # 路由配置

      "enabled": true├── stores/         # 状态管理

    }├── types/          # 类型定义

  }└── assets/         # 静态资源

}

```testlog/            # 测试日志文件夹

└── README.md       # 日志文件说明

> 💡 获取免费 API 密钥：[OpenWeatherMap](https://openweathermap.org/api)```



### 3️⃣ 安装依赖## 📊 日志分析功能



```bash### 测试日志文件

# 前端依赖

npm install项目提供了 `testlog/` 文件夹用于存放测试日志文件：



# 后端依赖- **位置**: 项目根目录下的 `testlog/` 文件夹

pip3 install flask flask-cors matplotlib- **格式**: 仅支持 `.log` 格式文件

```- **大小限制**: 单个文件不超过 30MB

- **用途**: 通过日志分析插件上传并分析日志数据

### 4️⃣ 启动服务

### 日志格式要求

**方式一：手动启动**

日志文件应包含时间戳、电流、温度、电压等数据，格式示例：

```bash

# 终端1：启动后端服务（端口 5002）```

python3 server.py2024-01-01 10:00:00 PM:INFO Current: 1234.56 μA, Temperature: 25.3°C, Voltage: 3.7V

```

# 终端2：启动前端服务（端口 3001）

npm run dev更多详情请查看 `testlog/README.md`

```

## 🔧 配置说明

**方式二：自动化脚本**

在 `public/config.json` 中配置 API 密钥和插件设置。

```bash

# 启动所有服务## 📝 开发新插件

./start-auto.sh

1. 在 `src/plugins/` 下创建插件目录

# 停止所有服务2. 创建插件组件和类型定义

./stop-auto.sh3. 在 `index.ts` 中导出插件元数据

```4. 在配置页面启用插件



### 5️⃣ 访问应用## 📄 License



- 🌐 本地访问：http://localhost:3001
- 🌐 局域网访问：http://[你的局域网IP]:3001（如：http://192.168.1.100:3001）

> 📖 详细配置说明请查看 [配置指南](./CONFIG_GUIDE.md)

## 📦 技术栈

### 前端

| 技术 | 版本 | 说明 |
|------|------|------|
| Vue 3 | 3.4.x | 渐进式 JavaScript 框架 |
| TypeScript | 5.6.x | JavaScript 的超集 |
| Vite | 7.1.x | 下一代前端构建工具 |
| Element Plus | 2.5.x | Vue 3 组件库 |
| ECharts | 6.0.x | 数据可视化图表库 |
| Vue Router | 4.2.x | 官方路由管理器 |
| Pinia | 2.1.x | 状态管理库 |

### 后端

| 技术 | 版本 | 说明 |
|------|------|------|
| Flask | 3.0.x | Python Web 框架 |
| Flask-CORS | 5.0.x | 跨域资源共享 |
| Matplotlib | 3.8.x | 图表生成库 |

## 📁 项目结构

```
sloan-toolkit-vue/
├── src/
│   ├── plugins/              # 插件目录
│   │   ├── info/            # 信息插件（天气+股票）
│   │   │   ├── InfoPlugin.vue
│   │   │   ├── index.ts
│   │   │   └── types/
│   │   └── log-analyzer/    # 日志分析插件
│   │       ├── LogAnalyzer.vue
│   │       └── index.ts
│   ├── views/               # 页面视图
│   │   ├── Home.vue
│   │   └── PluginConfig.vue
│   ├── router/              # 路由配置
│   ├── stores/              # 状态管理
│   └── types/               # 类型定义
├── backend/                 # 后端服务
│   ├── plugins/
│   │   └── log_analyzer/   # 日志分析后端
│   │       ├── parser.py   # 日志解析器
│   │       └── visualizer.py
│   ├── config/             # 配置模块
│   └── utils/              # 工具函数
├── server.py               # 后端入口
├── vite.config.ts          # Vite 配置
├── config.json             # 运行时配置
└── README.md              # 项目说明
```

## 🔧 配置说明

### Vite 配置（局域网访问）

```typescript
// vite.config.ts
export default defineConfig({
  server: {
    host: '0.0.0.0',  // 允许局域网访问
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:5002',
        changeOrigin: true
      }
    }
  }
})
```

### 后端配置

```python
# server.py
app.run(
    host='0.0.0.0',  # 允许局域网访问
    port=5002,
    debug=False
)
```

## 🎯 核心功能详解

### 信息插件

#### 天气查询
- **API**: OpenWeatherMap
- **支持功能**: 
  - 中英文城市名搜索
  - 实时天气数据
  - 收藏城市（最多10个）
  - 搜索历史（最近20条）
  - 体感温度、湿度、风速、气压

#### 股票信息
- **热门股票**: 今日涨幅榜 TOP5
  - 股票代码、名称
  - 最新价、涨跌幅
  - 换手率
  
- **龙虎榜**: 资金净流入 TOP5
  - 上一交易日数据
  - 收盘价、涨跌幅
  - 资金净流入（亿元）
  - 自动计算交易日（排除周末）

### 日志分析插件

#### 支持格式
1. **Key-Value 格式**: `BatteryLevel=100%, Voltage=...`
2. **数值格式**: `100 0 0 0 4080 26 0 1`

#### 分析功能
- **统计信息**:
  - 数据点总数
  - 电流平均值/最大值/最小值
  - 平均温度
  - 充电状态分布

- **可视化图表**:
  - 电流趋势图（自动单位转换）
  - 温度监控曲线
  - 电压波动图
  - 充电状态时序图

- **交互功能**:
  - 鼠标滚轮缩放
  - 拖拽平移
  - 框选缩放
  - 重置视图
  - 全屏展示

## 🐛 常见问题

### 1. 局域网无法访问？

**原因**: 服务器未绑定到 0.0.0.0

**解决方案**:
```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',  // ← 确保配置此项
  port: 3000
}
```

### 2. 日志分析返回 "load failed"？

**原因**: 后端服务未启动或API路径错误

**解决方案**:
1. 确认后端服务运行: `ps aux | grep python`
2. 检查API路径使用相对路径 `/api`
3. 查看浏览器控制台错误信息

### 3. 龙虎榜显示示例数据？

**原因**: API返回数据为空（可能是非交易日或API限制）

**说明**: 系统会自动降级到模拟数据，保证用户体验

### 4. 股票数据不刷新？

**解决方案**: 点击"刷新"按钮或刷新浏览器页面

## 📝 开发指南

### 添加新插件

1. 在 `src/plugins/` 创建插件文件夹
2. 创建组件文件和配置文件
3. 在 `src/views/Home.vue` 注册插件
4. 在 `src/views/PluginConfig.vue` 添加配置项

### 调试技巧

```bash
# 查看前端日志
npm run dev

# 查看后端日志
python3 server.py

# 查看网络请求
# 浏览器 DevTools → Network 标签
```

### 构建部署

```bash
# 构建生产版本
npm run build

# 输出目录: dist/
# 后端服务保持运行
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🔗 相关链接

- [Vue 3 文档](https://vuejs.org/)
- [Element Plus](https://element-plus.org/)
- [ECharts](https://echarts.apache.org/)
- [OpenWeatherMap API](https://openweathermap.org/api)
- [东方财富 API](https://www.eastmoney.com/)

## 📮 联系方式

- 项目地址: [https://github.com/chisl9403/webtest](https://github.com/chisl9403/webtest)
- 作者: Sloan

## 🙏 致谢

感谢以下开源项目：
- Vue.js 团队
- Element Plus 团队
- ECharts 团队
- Flask 社区

---

⭐ 如果这个项目对你有帮助，请给个 Star！
