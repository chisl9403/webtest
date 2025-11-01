"""
文件处理工具函数
"""

def allowed_file(filename, allowed_extensions={'log', 'txt'}):
    """检查文件扩展名是否允许"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in allowed_extensions

def safe_parse_float(value, default=0.0):
    """安全地将值转换为浮点数"""
    try:
        return float(value) if value is not None else default
    except (ValueError, TypeError):
        return default
