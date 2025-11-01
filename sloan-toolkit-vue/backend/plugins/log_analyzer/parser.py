"""
PM:INFO 日志解析器

支持的日志格式：
1. 键值对格式: PM:INFO curr=150 volt=4200 temp=25 charge=0
2. 数值格式: PM:INFO 83214 85 43090 -29781 26 2 0 -17187

数值格式说明（8个数值）：
[0] = 电量
[1] = UI电量
[2] = VBAT(电池电压) - 0.1mV单位
[3] = 电量
[4] = 温度 (°C) ← 倒数第4位
[5] = VBUS(充电电压)
[6] = 充电状态 (0-7) ← 倒数第2位
    0: 停充, 1: 放电, 2: 预充电, 3: CC恒流, 4: CV恒压, 5: 充满, 6: 完成, 7: 错误
[7] = 电流 (μA) ← 倒数第1位
"""
import re
import logging
from typing import Dict, List, Tuple, Optional

logger = logging.getLogger(__name__)


class PMInfoParser:
    """PM:INFO 格式日志文件解析器"""
    
    # 数据索引常量（数值格式）
    IDX_BATTERY_LEVEL = 0
    IDX_UI_BATTERY_LEVEL = 1
    IDX_VBAT = 2  # 电池电压
    IDX_BATTERY_LEVEL_2 = 3
    IDX_TEMPERATURE = 4
    IDX_VBUS = 5  # 充电电压
    IDX_CHARGE_STATE = 6
    IDX_CURRENT = 7
    
    # 充电状态映射
    CHARGE_STATES = {
        0: '停充',
        1: '放电',
        2: '预充电',
        3: 'CC恒流',
        4: 'CV恒压',
        5: '充满',
        6: '完成',
        7: '错误'
    }
    
    def __init__(self):
        """初始化解析器"""
        self.time_pattern = re.compile(r'\d{2}:\d{2}:\d{2}')
        self.value_pattern = re.compile(r'[-+]?\d*\.?\d+')
        self.key_value_pattern = re.compile(r'(\w+)=([-+]?\d*\.?\d+)')
    
    def is_valid_pm_info_line(self, line: str) -> bool:
        """
        检查是否为有效的 PM:INFO 行
        
        Args:
            line: 日志行文本
            
        Returns:
            bool: 是否为有效的PM:INFO行
        """
        line_upper = line.upper()
        if "PM:INFO" not in line_upper:
            return False
        
        # 提取 PM:INFO 后的内容
        info_start = line_upper.find("PM:INFO") + 7
        info_text = line[info_start:]
        
        # 检查是否为键值对格式或数值格式
        if '=' in info_text:
            # 键值对格式：至少需要curr, volt, temp, charge四个字段
            required_keys = {'curr', 'volt', 'temp', 'charge'}
            found_keys = set(match.group(1).lower() for match in self.key_value_pattern.finditer(info_text))
            return len(required_keys & found_keys) >= 3  # 至少3个关键字段
        else:
            # 数值格式：至少需要4个数值
            values = self.value_pattern.findall(info_text)
            return len(values) >= 4
    
    def safe_parse_float(self, value, default: float = 0.0) -> float:
        """
        安全地将值转换为浮点数
        
        Args:
            value: 待转换的值
            default: 转换失败时的默认值
            
        Returns:
            float: 转换后的浮点数
        """
        try:
            return float(value) if value is not None else default
        except (ValueError, TypeError):
            logger.debug(f"无法转换为浮点数: {value}, 使用默认值 {default}")
            return default
    
    def extract_time(self, line: str, line_number: int) -> str:
        """
        从行中提取时间
        
        支持的时间格式：
        1. I>36.508 格式（秒数）
        2. HH:MM:SS 格式
        3. 10/12 18:06:15 格式
        
        Args:
            line: 日志行文本
            line_number: 行号（作为后备时间）
            
        Returns:
            str: 格式化的时间字符串 (HH:MM:SS)
        """
        # 尝试提取各种时间格式
        patterns = [
            r'(\d{2}:\d{2}:\d{2})',  # HH:MM:SS
            r'I>(\d+\.\d+)',  # I>秒数
            r'\d{2}/\d{2}\s+(\d{2}:\d{2}:\d{2})',  # MM/DD HH:MM:SS
        ]
        
        for pattern in patterns:
            time_match = re.search(pattern, line)
            if time_match:
                try:
                    time_str = time_match.group(1)
                    
                    if ':' in time_str:
                        # 已经是 HH:MM:SS 格式
                        return time_str
                    else:
                        # 转换秒数为 HH:MM:SS
                        seconds = float(time_str)
                        hours = int(seconds // 3600)
                        minutes = int((seconds % 3600) // 60)
                        secs = int(seconds % 60)
                        return f"{hours:02d}:{minutes:02d}:{secs:02d}"
                except Exception as e:
                    logger.warning(f"第 {line_number} 行时间解析错误: {str(e)}")
        
        # 使用行号作为后备时间
        seconds = line_number % 3600
        minutes = (line_number // 60) % 60
        hours = (line_number // 3600) % 24
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}"
    
    def parse_key_value_format(self, info_text: str) -> Tuple[float, float, float, int]:
        """
        解析键值对格式的数据
        
        格式: curr=150 volt=4200 temp=25 charge=0
        
        Args:
            info_text: PM:INFO 后的文本
            
        Returns:
            Tuple[电流, 电压, 温度, 充电状态]
        """
        current = 0.0
        voltage = 0.0
        temp = 0.0
        charging = 0
        
        for match in self.key_value_pattern.finditer(info_text):
            key = match.group(1).lower()
            value = match.group(2)
            
            if key == 'curr':
                current = self.safe_parse_float(value)
            elif key == 'volt':
                voltage = self.safe_parse_float(value)
                # 键值对格式的电压单位是mV，转换为V
                if voltage > 1000:
                    voltage = voltage / 1000.0
            elif key == 'temp':
                temp = self.safe_parse_float(value)
            elif key == 'charge':
                charging = int(self.safe_parse_float(value))
                # 确保状态值在有效范围内
                if charging < 0 or charging > 7:
                    logger.warning(f"充电状态值异常: {charging}, 重置为0")
                    charging = 0
        
        return current, voltage, temp, charging
    
    def parse_numeric_format(self, info_text: str, line_number: int) -> Tuple[float, float, float, int]:
        """
        解析数值格式的数据
        
        格式: 83214 85 43090 -29781 26 2 0 -17187
        
        Args:
            info_text: PM:INFO 后的文本
            line_number: 行号（用于日志）
            
        Returns:
            Tuple[电流, 电压, 温度, 充电状态]
        """
        values = self.value_pattern.findall(info_text)
        
        if len(values) < 8:
            logger.warning(f"第 {line_number} 行数值不足8个，实际找到 {len(values)} 个")
            values.extend(['0'] * (8 - len(values)))
        
        # 提取数据
        current = self.safe_parse_float(values[self.IDX_CURRENT] if len(values) > self.IDX_CURRENT else 0)
        vbat = self.safe_parse_float(values[self.IDX_VBAT] if len(values) > self.IDX_VBAT else 0)
        temp = self.safe_parse_float(values[self.IDX_TEMPERATURE] if len(values) > self.IDX_TEMPERATURE else 0)
        charging = int(self.safe_parse_float(values[self.IDX_CHARGE_STATE] if len(values) > self.IDX_CHARGE_STATE else 0))
        
        # 验证充电状态
        if charging < 0 or charging > 7:
            logger.warning(f"第 {line_number} 行充电状态值异常: {charging}, 重置为0")
            charging = 0
        
        # 转换电压单位 (0.1mV -> V)
        # 例如：43090 表示 4309.0 mV，除以10000得到 4.309 V
        if vbat > 1000:
            vbat = vbat / 10000.0
        
        return current, vbat, temp, charging
    
    def extract_values(self, line: str, line_number: int) -> Tuple[float, float, float, int]:
        """
        从行中提取数值
        
        Args:
            line: 日志行文本
            line_number: 行号
            
        Returns:
            Tuple[电流(μA), 电压(V), 温度(°C), 充电状态(0-7)]
        """
        try:
            # 提取 PM:INFO 后的内容
            info_start = line.upper().find("PM:INFO") + 7
            info_text = line[info_start:]
            
            # 根据格式选择解析方法
            if '=' in info_text:
                return self.parse_key_value_format(info_text)
            else:
                return self.parse_numeric_format(info_text, line_number)
                
        except Exception as e:
            logger.error(f"第 {line_number} 行数值解析失败: {str(e)}")
            return 0.0, 0.0, 0.0, 0
    
    def parse_file(self, file_path: str) -> Dict[str, List]:
        """
        解析日志文件
        
        Args:
            file_path: 日志文件路径
            
        Returns:
            Dict: 包含时间序列数据的字典
                - times: 时间列表
                - currents: 电流列表 (μA)
                - temperatures: 温度列表 (°C)
                - voltages: 电压列表 (V)
                - charging_states: 充电状态列表 (0-7)
                
        Raises:
            ValueError: 文件读取或解析失败
        """
        logger.info(f"开始解析文件: {file_path}")
        
        # 初始化数据容器
        times = []
        currents = []
        temperatures = []
        voltages = []
        charging_states = []
        
        # 读取文件
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.readlines()
                logger.info(f"成功读取文件，共 {len(content)} 行")
        except Exception as e:
            error_msg = f"读取文件失败: {str(e)}"
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        # 预验证：检查文件是否包含有效数据
        valid_lines = [line for line in content if self.is_valid_pm_info_line(line)]
        if not valid_lines:
            error_msg = "文件中未找到有效的 PM:INFO 数据行"
            logger.error(error_msg)
            raise ValueError(error_msg + "。请确认文件格式是否正确。")
        
        logger.info(f"找到 {len(valid_lines)} 行有效的 PM:INFO 数据")
        
        # 解析每一行
        parse_errors = 0
        for line_number, line in enumerate(content, 1):
            try:
                if not self.is_valid_pm_info_line(line):
                    continue
                
                # 提取时间和数值
                time = self.extract_time(line, line_number)
                current, voltage, temp, charging = self.extract_values(line, line_number)
                
                # 添加到列表
                times.append(time)
                currents.append(current)
                temperatures.append(temp)
                voltages.append(voltage)
                charging_states.append(charging)
                
            except Exception as e:
                parse_errors += 1
                logger.warning(f"处理第 {line_number} 行时出错: {str(e)}")
                if parse_errors > 10:
                    logger.error("解析错误过多，终止解析")
                    break
                continue
        
        # 验证解析结果
        if not times:
            error_msg = "未能成功解析任何 PM:INFO 数据行"
            logger.error(error_msg)
            raise ValueError(error_msg + "。请检查文件内容是否正确。")
        
        logger.info(f"✅ 成功解析 {len(times)} 条数据")
        if parse_errors > 0:
            logger.warning(f"⚠️ 解析过程中跳过了 {parse_errors} 行错误数据")
        
        # 返回结果
        return {
            'times': times,
            'currents': currents,
            'temperatures': temperatures,
            'voltages': voltages,
            'charging_states': charging_states
        }
