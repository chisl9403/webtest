"""
应用配置文件
"""
import tempfile

class AppConfig:
    """Flask 应用配置"""
    
    # 上传配置
    UPLOAD_FOLDER = tempfile.gettempdir()
    MAX_CONTENT_LENGTH = 30 * 1024 * 1024  # 最大 30MB
    ALLOWED_EXTENSIONS = {'log', 'txt'}
    
    # 服务器配置
    HOST = '0.0.0.0'
    PORT = 5002
    DEBUG = False
    
    # CORS 配置
    CORS_ORIGINS = "*"
    
    # 日志配置
    LOG_LEVEL = 'DEBUG'
