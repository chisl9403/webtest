#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Flask 后端服务器 - 主入口
支持插件化架构，便于扩展新功能
"""

from flask import Flask
from flask_cors import CORS
import os
import sys
import logging
import tempfile

# 配置日志
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 添加 backend 目录到 Python 路径
backend_dir = os.path.join(os.path.dirname(__file__), 'backend')
sys.path.insert(0, backend_dir)

# 导入配置和工具
from config.settings import AppConfig
from utils.logger import setup_logger
from utils.matplotlib_config import setup_matplotlib

# 导入插件
from plugins.log_analyzer import log_analyzer_bp

# 导入 RSS 代理插件
try:
    from plugins.rss_proxy import rss_proxy_bp
    HAS_RSS_PROXY = True
    logger.info("✓ RSS代理插件加载成功")
except Exception as e:
    HAS_RSS_PROXY = False
    logger.error(f"✗ RSS代理插件加载失败: {e}")
    import traceback
    logger.error(traceback.format_exc())
    
# 可以在此处导入更多插件
# from plugins.weather import weather_bp
# from plugins.other_plugin import other_plugin_bp

def create_app():
    """创建并配置 Flask 应用"""
    app = Flask(__name__)
    
    # 加载配置
    app.config.from_object(AppConfig)
    
    # 启用 CORS
    CORS(app, resources={r"/*": {"origins": "*"}})
    
    # 配置 matplotlib
    setup_matplotlib()
    
    # 注册蓝图（插件）
    app.register_blueprint(log_analyzer_bp, url_prefix='/api')
    
    # 注册 RSS 代理插件（如果可用）
    if HAS_RSS_PROXY:
        app.register_blueprint(rss_proxy_bp, url_prefix='/api')
        logger.info("✓ RSS代理插件已注册")
    
    # 注册更多插件
    # app.register_blueprint(weather_bp, url_prefix='/api')
    # app.register_blueprint(other_plugin_bp, url_prefix='/api')
    
    # 健康检查端点
    @app.route('/', methods=['GET'])
    def health_check():
        """健康检查端点"""
        from flask import jsonify
        plugins = [
            {'name': 'log-analyzer', 'endpoint': '/api/analyze'}
        ]
        # 动态检查插件是否已注册
        if 'rss_proxy' in app.blueprints:
            plugins.append({'name': 'rss-proxy', 'endpoint': '/api/36kr/rss'})
            
        return jsonify({
            'status': 'ok',
            'message': 'Flask server is running',
            'version': '2.0.0',
            'plugins': plugins
        })
    
    # 全局异常处理
    @app.errorhandler(Exception)
    def handle_exception(e):
        """全局异常处理"""
        import traceback
        from flask import jsonify
        logger.error(f"未处理的异常: {str(e)}")
        logger.error(traceback.format_exc())
        return jsonify({
            'error': f'服务器内部错误: {str(e)}',
            'details': traceback.format_exc()
        }), 500
    
    return app

def check_config_files():
    """检查配置文件并返回优先级最高的配置"""
    import json
    
    config_files = [
        'config.local.json',  # 优先级最高（本地配置）
        'config.json',        # 次优先级（通用配置）
        'config.example.json' # 最低优先级（示例配置）
    ]
    
    logger.info("=" * 60)
    logger.info("配置文件检查")
    logger.info("=" * 60)
    
    found_configs = []
    for config_file in config_files:
        file_path = os.path.join(os.getcwd(), config_file)
        if os.path.exists(file_path):
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    config_data = json.load(f)
                    api_key = config_data.get('apiKey', '')
                    
                    # 检查是否是占位符
                    is_placeholder = any(placeholder in api_key.upper() for placeholder in [
                        'YOUR_', 'OPENWEATHERMAP', 'API_KEY', '请在此处填写'
                    ])
                    
                    status = "⚠️  未配置（占位符）" if is_placeholder else "✅ 已配置"
                    found_configs.append({
                        'file': config_file,
                        'path': file_path,
                        'exists': True,
                        'valid': not is_placeholder,
                        'api_key': api_key[:20] + '...' if len(api_key) > 20 else api_key
                    })
                    logger.info(f"{status} - {config_file}")
                    if not is_placeholder:
                        logger.info(f"         API Key: {api_key[:8]}...{api_key[-4:]}")
            except Exception as e:
                logger.error(f"❌ 读取失败 - {config_file}: {e}")
                found_configs.append({
                    'file': config_file,
                    'path': file_path,
                    'exists': True,
                    'valid': False,
                    'error': str(e)
                })
        else:
            logger.info(f"⊘  不存在 - {config_file}")
    
    # 找到第一个有效配置
    valid_config = next((c for c in found_configs if c.get('valid')), None)
    
    if valid_config:
        logger.info("=" * 60)
        logger.info(f"✅ 使用配置: {valid_config['file']}")
        logger.info("=" * 60)
    else:
        logger.warning("=" * 60)
        logger.warning("⚠️  警告: 未找到有效的 API 配置！")
        logger.warning("请编辑 config.local.json 或 config.json 添加有效的 API Key")
        logger.warning("获取免费 API Key: https://openweathermap.org/api")
        logger.warning("=" * 60)
    
    return found_configs

if __name__ == '__main__':
    # 检查配置文件
    check_config_files()
    
    # 确保上传文件夹存在
    upload_folder = tempfile.gettempdir()
    os.makedirs(upload_folder, exist_ok=True)
    
    logger.info(f"启动服务器，上传文件夹：{upload_folder}")
    logger.info(f"Python 版本：{sys.version}")
    logger.info(f"工作目录：{os.getcwd()}")
    
    # 创建应用
    app = create_app()
    
    # 运行服务器（支持 IPv4 和 IPv6）
    app.run(
        host='::',  # 监听所有 IPv6 地址（也支持 IPv4）
        port=5002,
        debug=False,
        use_reloader=False
    )
