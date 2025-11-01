#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import tempfile
import traceback
import logging
from werkzeug.utils import secure_filename
import sys
import matplotlib
matplotlib.use('Agg')  # 设置 matplotlib 后端
import matplotlib.pyplot as plt
import base64
from io import BytesIO

# 配置日志
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# 配置 matplotlib 使用中文字体 - 适配 macOS
import platform
if platform.system() == 'Darwin':  # macOS
    plt.rcParams['font.sans-serif'] = [
        'Arial Unicode MS',     # 最佳中英文混合显示
        'Hiragino Sans GB',     # 苹果黑体简体
        'Heiti TC',             # 黑体繁体
        'STHeiti',              # 华文黑体
        'PingFang SC',          # 苹方简体
        'Songti SC'             # 宋体简体
    ]
elif platform.system() == 'Windows':
    plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei']
else:  # Linux
    plt.rcParams['font.sans-serif'] = ['WenQuanYi Micro Hei', 'Noto Sans CJK SC', 'DejaVu Sans']

plt.rcParams['axes.unicode_minus'] = False  # 用来正常显示负号
logger.info(f"matplotlib 字体设置: {plt.rcParams['font.sans-serif']}")

# 应用配置
UPLOAD_FOLDER = tempfile.gettempdir()
ALLOWED_EXTENSIONS = {'log'}

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})  # 启用跨域请求支持，允许所有来源

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def safe_parse_float(value, default=0.0):
    """安全地将值转换为浮点数"""
    try:
        return float(value) if value is not None else default
    except (ValueError, TypeError):
        return default

def process_pm_info_file(file_path):
    """处理 PM:INFO 文件并返回分析数据"""
    logger.info(f"开始处理文件: {file_path}")
    
    # 读取并解析文件
    times = []
    currents = []
    temperatures = []
    voltages = []
    charging_states = []
    
    # 定义 PM:INFO 行的基本格式验证
    def is_valid_pm_info_line(line):
        line_upper = line.upper()
        # 必须包含PM:INFO
        if "PM:INFO" not in line_upper:
            return False
        
        # 提取PM:INFO后的所有数值
        values = re.findall(r'[-+]?\d*\.?\d+', line[line_upper.find("PM:INFO") + 7:])
        return len(values) >= 8  # 需要至少8个数值字段
    
    logger.info("开始解析文件...")
    
    import re
    time_pattern = re.compile(r'\d{2}:\d{2}:\d{2}')
    value_pattern = re.compile(r'[-+]?\d*\.?\d+')
    
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.readlines()
            logger.info(f"成功读取文件，共 {len(content)} 行")
            # 打印前几行用于调试
            for i, line in enumerate(content[:5]):
                logger.debug(f"第 {i+1} 行: {line.strip()}")
    except Exception as e:
        logger.error(f"读取文件失败: {str(e)}")
        logger.error(traceback.format_exc())
        raise ValueError(f"读取文件失败: {str(e)}")
        
    if not any(is_valid_pm_info_line(line) for line in content):
        raise ValueError("文件中未找到有效的 PM:INFO 数据行")
    
    for line_number, line in enumerate(content, 1):
        try:
            if not is_valid_pm_info_line(line):
                continue
            
            # 提取时间
            time_match = re.search(r'I>(\d+\.\d+)', line) or re.search(r'(\d{2}:\d{2}:\d{2}\.\d+)', line)
            if time_match:
                try:
                    time_str = time_match.group(1)
                    if ':' in time_str:  # 已经是HH:MM:SS格式
                        time = time_str.split('.')[0]
                    else:  # I>秒数格式
                        seconds = float(time_str)
                        minutes = int(seconds // 60)
                        seconds = int(seconds % 60)
                        time = f"00:{minutes:02d}:{seconds:02d}"
                except Exception as e:
                    logger.warning(f"第 {line_number} 行时间格式错误: {str(e)}")
                    time = f"00:00:{line_number}"  # 使用行号作为后备时间
            else:
                logger.warning(f"第 {line_number} 行未找到时间信息，使用默认时间")
                time = f"00:00:{line_number}"  # 使用行号作为后备时间
            
            # 提取数值
            try:
                info_text = line[line.upper().find("PM:INFO") + 7:]
                values = value_pattern.findall(info_text)
                
                if len(values) < 8:
                    logger.warning(f"第 {line_number} 行数值不足8个，实际找到 {len(values)} 个")
                    # 填充缺失值为0
                    values.extend([0] * (8 - len(values)))
                
                # 确保至少有8个数值
                current = safe_parse_float(values[7] if len(values) > 7 else 0)
                vbat_voltage = safe_parse_float(values[2] if len(values) > 2 else 0)
                temp = safe_parse_float(values[5] if len(values) > 5 else 0)
                charging = 1 if (values[6] == "1" if len(values) > 6 else 0) else 0
                
            except Exception as e:
                logger.error(f"第 {line_number} 行数值解析失败: {str(e)}")
                # 使用默认值继续处理
                current = 0
                vbat_voltage = 0
                temp = 0
                charging = 0
            
            # 处理新格式：I>5.303 VOLT sys_work PM:INFO 82726 84 42950 218 64 5074 1 31
            if "VOLT sys_work PM:INFO" in line:
                if len(values) >= 8:
                    current = safe_parse_float(values[7])  # 第8个值是电流
                    vbat_voltage = safe_parse_float(values[2])  # 第3个值是VBAT电压
                    temp = safe_parse_float(values[5])     # 第6个值是温度
                    charging = 1 if values[6] == "1" else 0  # 第7个值是充电状态
                else:
                    current = safe_parse_float(values[-1]) if values else 0
                    vbat_voltage = safe_parse_float(values[2]) if len(values) > 2 else 0
                    temp = safe_parse_float(values[4]) if len(values) > 4 else 0
                    charging = 1 if "充电中" in line or "CHARGING" in line.upper() else 0
            else:
                # 保留旧格式处理逻辑
                if len(values) >= 9:
                    current = safe_parse_float(values[8])
                    vbat_voltage = safe_parse_float(values[3])
                    temp = safe_parse_float(values[5])
                    charging = 1 if values[7] == "1" else 0
                else:
                    current = safe_parse_float(values[-1]) if values else 0
                    vbat_voltage = safe_parse_float(values[2]) if len(values) > 2 else 0
                    temp = safe_parse_float(values[4]) if len(values) > 4 else 0
                    charging = 1 if "充电中" in line or "CHARGING" in line.upper() else 0
            
            times.append(time)
            currents.append(current)
            temperatures.append(temp)
            voltages.append(vbat_voltage/10000.0 if vbat_voltage > 1000 else vbat_voltage)  # 使用正确的变量名并转换电压单位
            charging_states.append(charging)
            
        except Exception as e:
            logger.warning(f"处理第 {line_number} 行时出错：{str(e)}")
            continue
    
            if not times:
                error_msg = "未能成功解析任何 PM:INFO 数据行"
                logger.error(error_msg)
                logger.error("文件内容示例:")
                for i, line in enumerate(content[:20]):  # 打印前20行用于调试
                    logger.error(f"第{i+1}行: {line.strip()}")
                raise ValueError(error_msg + "。请确认文件包含有效的PM:INFO数据")
        
    logger.info(f"成功解析 {len(times)} 条数据")
    
    # 生成图表
    plt.style.use('default')  # 使用默认样式替代seaborn
    
    # 确保使用正确的字体
    import matplotlib.font_manager as fm
    available_fonts = [f.name for f in fm.fontManager.ttflist]
    logger.info(f"可用字体数量: {len(available_fonts)}")
    
    # 测试字体设置
    test_fonts = ['Arial Unicode MS', 'Hiragino Sans GB', 'STHeiti']
    for font in test_fonts:
        if font in available_fonts:
            logger.info(f"✓ 找到字体: {font}")
            plt.rcParams['font.sans-serif'] = [font] + plt.rcParams['font.sans-serif']
            break
    
    logger.info(f"当前字体配置: {plt.rcParams['font.sans-serif']}")
    
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 12))
    fig.patch.set_facecolor('#f8f9fa')
    # 设置网格样式
    for ax in [ax1, ax2, ax3]:
        ax.grid(True, linestyle='--', alpha=0.7)
    
    # 绘制电流图
    ax1.plot(range(len(times)), currents, '-b', label='电流(mA)', linewidth=1)
    ax1.set_title('电流变化趋势', fontsize=14, fontweight='bold', pad=15)
    ax1.set_ylabel('电流 (mA)', fontsize=12)
    ax1.grid(True, linestyle='--', alpha=0.7)
    
    # 绘制温度图
    ax2.plot(range(len(times)), temperatures, '-r', label='温度(°C)', linewidth=1)
    ax2.set_title('温度变化趋势', fontsize=14, fontweight='bold', pad=15)
    ax2.set_ylabel('温度 (°C)', fontsize=12)
    ax2.grid(True, linestyle='--', alpha=0.7)
    
    # 绘制电压图
    ax3.plot(range(len(times)), voltages, '-g', label='电压(V)', linewidth=1)
    ax3.set_title('电压变化趋势', fontsize=14, fontweight='bold', pad=15)
    ax3.set_xlabel('时间', fontsize=12)
    ax3.set_ylabel('电压 (V)', fontsize=12)
    ax3.grid(True, linestyle='--', alpha=0.7)
    
    # 设置x轴标签
    for ax in [ax1, ax2, ax3]:
        num_points = len(times)
        step = max(1, num_points // 10)
        ax.set_xticks(range(0, num_points, step))
        ax.set_xticklabels([times[i] for i in range(0, num_points, step)], rotation=45)
        ax.legend(loc='upper right')
    
    plt.tight_layout()
    
    # 将图表转换为base64字符串
    buffer = BytesIO()
    plt.savefig(buffer, format='png', dpi=100, bbox_inches='tight')
    buffer.seek(0)
    image_png = buffer.getvalue()
    buffer.close()
    plt.close()
    
    # 计算统计数据
    stats = {
        'total_points': len(times),
        'avg_current': sum(currents) / len(currents) if currents else 0,
        'max_current': max(currents) if currents else 0,
        'min_current': min(currents) if currents else 0,
        'avg_temp': sum(temperatures) / len(temperatures) if temperatures else 0,
        'max_temp': max(temperatures) if temperatures else 0,
        'min_temp': min(temperatures) if temperatures else 0,
        'avg_voltage': sum(voltages) / len(voltages) if voltages else 0,
        'charging_time': sum(1 for state in charging_states if state == 1),
    }
    
    logger.info("图表生成完成")
    return {
        'graph': base64.b64encode(image_png).decode('utf-8'),
        'stats': stats
    }

@app.route('/', methods=['GET'])
def health_check():
    """健康检查端点"""
    return jsonify({
        'status': 'ok',
        'message': 'Flask server is running',
        'endpoints': ['/api/analyze']
    })

@app.route('/api/analyze', methods=['POST'])
def analyze_file():
    logger.info("收到文件上传请求")
    if 'file' not in request.files:
        logger.error("请求中没有文件")
        return jsonify({'error': '没有文件上传'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': '没有选择文件'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        temp_path = os.path.join(UPLOAD_FOLDER, filename)
        
        try:
            # 检查文件对象
            logger.info(f"文件名: {file.filename}, 文件类型: {file.content_type}")
            
            # 保存文件
            file.save(temp_path)
            logger.info(f"文件已保存到：{temp_path}")
            
            # 检查文件大小
            file_size = os.path.getsize(temp_path)
            logger.info(f"文件大小：{file_size} 字节")
            
            if file_size == 0:
                raise ValueError("文件为空")
            
            logger.info(f"开始处理文件，大小：{file_size} 字节")
            
            # 检查文件内容 - 检查更多行以找到 PM:INFO
            has_pm_info = False
            with open(temp_path, 'r', encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f):
                    if "PM:INFO" in line.upper():
                        has_pm_info = True
                        logger.info(f"在第 {i+1} 行找到 PM:INFO")
                        break
                    if i >= 100:  # 检查前100行就足够了
                        break
                
                if not has_pm_info:
                    raise ValueError("文件中未找到 PM:INFO 内容，请确认文件格式是否正确")
            
            # 处理 PM:INFO 日志文件
            result = process_pm_info_file(temp_path)
            return jsonify(result)
            
        except ValueError as ve:
            error_msg = f"数据验证错误: {str(ve)}"
            logger.error(error_msg)
            logger.error("文件内容前5行:")
            with open(temp_path, 'r', encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f):
                    if i >= 5: break
                    logger.error(f"第{i+1}行: {line.strip()}")
            return jsonify({'error': error_msg, 'details': '请检查文件格式是否符合要求'}), 400
        except Exception as e:
            error_msg = f"处理文件时出错：{str(e)}"
            logger.error(error_msg)
            logger.error(traceback.format_exc())
            logger.error("错误发生时文件内容:")
            with open(temp_path, 'r', encoding='utf-8', errors='ignore') as f:
                for i, line in enumerate(f):
                    if i >= 20: break  # 打印前20行用于调试
                    logger.error(f"第{i+1}行: {line.strip()}")
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
    
    return jsonify({'error': '不支持的文件类型'}), 400

@app.errorhandler(Exception)
def handle_exception(e):
    """全局异常处理"""
    logger.error(f"未处理的异常: {str(e)}")
    logger.error(traceback.format_exc())
    return jsonify({
        'error': f'服务器内部错误: {str(e)}',
        'details': traceback.format_exc()
    }), 500

if __name__ == '__main__':
    # 确保上传文件夹存在
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    logger.info(f"启动服务器，上传文件夹：{UPLOAD_FOLDER}")
    logger.info(f"Python 版本：{sys.version}")
    logger.info(f"工作目录：{os.getcwd()}")
    # 使用生产模式避免调试模式的重启问题
    app.run(host='0.0.0.0', port=5002, debug=False, use_reloader=False)