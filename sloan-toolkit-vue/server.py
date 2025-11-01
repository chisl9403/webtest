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
    # 注册更多插件
    # app.register_blueprint(weather_bp, url_prefix='/api')
    # app.register_blueprint(other_plugin_bp, url_prefix='/api')
    
    # 健康检查端点
    @app.route('/', methods=['GET'])
    def health_check():
        """健康检查端点"""
        from flask import jsonify
        return jsonify({
            'status': 'ok',
            'message': 'Flask server is running',
            'version': '2.0.0',
            'plugins': [
                {'name': 'log-analyzer', 'endpoint': '/api/analyze'},
                # 在此添加更多插件信息
            ]
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

if __name__ == '__main__':
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
