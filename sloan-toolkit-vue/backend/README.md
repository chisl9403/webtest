# 后端架构说明

## 概述

本后端采用模块化、插件化架构，便于扩展和维护。Flask 应用使用工厂模式创建，各功能模块独立管理。

## 目录结构

```
backend/
├── config/              # 配置模块
│   ├── __init__.py
│   └── settings.py      # 应用配置类
├── utils/               # 工具模块
│   ├── __init__.py
│   ├── logger.py        # 日志配置
│   ├── matplotlib_config.py  # Matplotlib 中文字体配置
│   └── file_utils.py    # 文件处理工具
└── plugins/             # 插件模块
    └── log_analyzer/    # 日志分析插件
        ├── __init__.py  # Flask Blueprint 路由
        ├── parser.py    # PM:INFO 日志解析器
        └── visualizer.py # 数据可视化工具

server.py                # 应用主入口
server_old.py            # 旧版服务器（备份）
```

## 核心组件

### 1. 配置模块 (`backend/config/`)

**settings.py**
- `AppConfig` 类：集中管理所有应用配置
- 包含：上传目录、文件大小限制、允许的文件扩展名、服务器端口等

### 2. 工具模块 (`backend/utils/`)

**logger.py**
- `setup_logger()`: 配置日志记录器

**matplotlib_config.py**
- `setup_matplotlib()`: 配置 matplotlib 以支持中文字体
- 自动检测操作系统并设置合适的中文字体

**file_utils.py**
- `allowed_file()`: 验证文件扩展名
- `safe_parse_float()`: 安全解析浮点数

### 3. 插件模块 (`backend/plugins/`)

每个插件是一个独立的包，使用 Flask Blueprint 实现路由。

#### log_analyzer 插件

**__init__.py**
- 定义 Flask Blueprint: `log_analyzer_bp`
- 路由: `POST /api/analyze` - 接收日志文件并返回分析结果

**parser.py**
- `PMInfoParser` 类：解析 PM:INFO 格式的日志文件
- 提取时间、电流、温度、电压、充电状态数据
- 支持新旧两种 PM:INFO 格式

**visualizer.py**
- `PMInfoVisualizer` 类：生成数据可视化图表
- 创建电流、温度、电压三个子图
- 返回 base64 编码的图表和统计数据

## 添加新插件

### 步骤

1. 在 `backend/plugins/` 下创建新的包目录，例如 `weather/`

2. 创建 `__init__.py` 定义 Blueprint：

```python
from flask import Blueprint

weather_bp = Blueprint('weather', __name__)

@weather_bp.route('/weather', methods=['GET'])
def get_weather():
    # 实现天气查询逻辑
    return {'status': 'ok'}
```

3. 在 `server.py` 中注册插件：

```python
from plugins.weather import weather_bp

def create_app():
    # ...
    app.register_blueprint(weather_bp, url_prefix='/api')
    # ...
```

4. 更新健康检查端点的插件列表：

```python
@app.route('/', methods=['GET'])
def health_check():
    return jsonify({
        'plugins': [
            {'name': 'log-analyzer', 'endpoint': '/api/analyze'},
            {'name': 'weather', 'endpoint': '/api/weather'},  # 新插件
        ]
    })
```

### 插件开发规范

- 每个插件是独立的 Python 包
- 使用 Flask Blueprint 管理路由
- 插件内部模块化：分离数据处理、业务逻辑、API 路由
- 统一使用 `utils` 模块中的工具函数
- 添加详细的日志记录
- 完善的错误处理

## 运行服务器

### 开发模式

```bash
python3 server.py
```

### 后台运行

```bash
nohup python3 server.py > server.log 2>&1 &
```

### 使用自动化脚本

```bash
# 启动服务
./start-auto.sh

# 停止服务
./stop-auto.sh

# 部署更新
./deploy-auto.sh
```

## API 端点

### 健康检查
- **URL**: `GET /`
- **响应**: 服务器状态和已注册插件列表

### 日志分析
- **URL**: `POST /api/analyze`
- **参数**: `file` (multipart/form-data)
- **响应**: 包含分析图表和统计数据的 JSON

## 技术栈

- **Web 框架**: Flask 2.x
- **数据可视化**: Matplotlib 3.x
- **跨域支持**: Flask-CORS
- **Python 版本**: 3.9+

## 优势

1. **模块化**：各功能模块独立，易于维护和测试
2. **可扩展**：通过 Blueprint 系统轻松添加新插件
3. **解耦**：配置、工具、业务逻辑分离
4. **可读性**：清晰的目录结构和命名规范
5. **可维护**：代码组织良好，便于协作开发

## 迁移说明

原有的 387 行 `server.py` 已被重构为模块化架构：
- 旧版本已备份为 `server_old.py`
- 新版本使用工厂模式和插件系统
- 所有功能保持不变，但代码结构更清晰

## 后续改进建议

1. 添加单元测试和集成测试
2. 实现配置文件热加载
3. 添加插件依赖管理
4. 实现插件热插拔
5. 添加 API 文档（Swagger/OpenAPI）
6. 使用生产级 WSGI 服务器（Gunicorn/uWSGI）
