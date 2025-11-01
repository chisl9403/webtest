"""
日志分析插件 - PM:INFO 日志文件分析
"""
from flask import Blueprint, request, jsonify
from werkzeug.utils import secure_filename
import os
import tempfile
import logging
import traceback

from .parser import PMInfoParser
from .visualizer import PMInfoVisualizer
from utils.file_utils import allowed_file

logger = logging.getLogger(__name__)

# 创建蓝图
log_analyzer_bp = Blueprint('log_analyzer', __name__)

@log_analyzer_bp.route('/analyze', methods=['POST'])
def analyze_file():
    """分析上传的日志文件"""
    logger.info("收到文件上传请求")
    
    # 验证文件
    if 'file' not in request.files:
        logger.error("请求中没有文件")
        return jsonify({'error': '没有文件上传'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': '没有选择文件'}), 400
    
    if not file or not allowed_file(file.filename):
        return jsonify({'error': '不支持的文件类型'}), 400
    
    filename = secure_filename(file.filename)
    temp_path = os.path.join(tempfile.gettempdir(), filename)
    
    try:
        # 保存文件
        file.save(temp_path)
        logger.info(f"文件已保存到：{temp_path}")
        
        # 检查文件大小
        file_size = os.path.getsize(temp_path)
        logger.info(f"文件大小：{file_size} 字节")
        
        if file_size == 0:
            raise ValueError("文件为空")
        
        # 快速检查文件内容
        has_pm_info = False
        with open(temp_path, 'r', encoding='utf-8', errors='ignore') as f:
            for i, line in enumerate(f):
                if "PM:INFO" in line.upper():
                    has_pm_info = True
                    logger.info(f"在第 {i+1} 行找到 PM:INFO")
                    break
                if i >= 100:
                    break
        
        if not has_pm_info:
            raise ValueError("文件中未找到 PM:INFO 内容，请确认文件格式是否正确")
        
        # 解析文件
        parser = PMInfoParser()
        data = parser.parse_file(temp_path)
        
        # 计算统计数据
        from .visualizer import PMInfoVisualizer
        visualizer = PMInfoVisualizer()
        stats = visualizer._calculate_statistics(
            data['currents'], 
            data['temperatures'], 
            data['voltages'], 
            data['charging_states']
        )
        
        # 返回原始数据和统计信息（用于前端动态图表）
        result = {
            'data': data,  # 原始时间序列数据
            'stats': stats  # 统计信息
        }
        
        return jsonify(result)
        
    except ValueError as ve:
        error_msg = f"数据验证错误: {str(ve)}"
        logger.error(error_msg)
        return jsonify({
            'error': error_msg,
            'details': '请检查文件格式是否符合要求'
        }), 400
        
    except Exception as e:
        error_msg = f"处理文件时出错：{str(e)}"
        logger.error(error_msg)
        logger.error(traceback.format_exc())
        return jsonify({
            'error': '文件处理失败',
            'details': error_msg,
            'trace': traceback.format_exc()
        }), 500
        
    finally:
        # 清理临时文件
        if os.path.exists(temp_path):
            try:
                os.remove(temp_path)
                logger.info(f"临时文件已删除: {temp_path}")
            except Exception as e:
                logger.warning(f"清理临时文件失败：{str(e)}")
