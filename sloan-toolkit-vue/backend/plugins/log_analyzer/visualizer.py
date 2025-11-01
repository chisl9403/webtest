"""
PM:INFO 数据可视化
"""
import matplotlib.pyplot as plt
import base64
from io import BytesIO
import logging
from typing import Dict, List

logger = logging.getLogger(__name__)

class PMInfoVisualizer:
    """PM:INFO 数据可视化工具"""
    
    def create_charts(self, data: Dict[str, List]) -> Dict:
        """创建图表并返回结果"""
        times = data['times']
        currents = data['currents']
        temperatures = data['temperatures']
        voltages = data['voltages']
        charging_states = data['charging_states']
        
        # 使用默认样式
        plt.style.use('default')
        
        # 创建图表
        fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 12))
        fig.patch.set_facecolor('#f8f9fa')
        
        # 设置网格样式
        for ax in [ax1, ax2, ax3]:
            ax.grid(True, linestyle='--', alpha=0.7)
        
        # 绘制电流图
        ax1.plot(range(len(times)), currents, '-b', label='电流(mA)', linewidth=1)
        ax1.set_title('电流变化趋势', fontsize=14, fontweight='bold', pad=15)
        ax1.set_ylabel('电流 (mA)', fontsize=12)
        ax1.legend(loc='upper right')
        
        # 绘制温度图
        ax2.plot(range(len(times)), temperatures, '-r', label='温度(°C)', linewidth=1)
        ax2.set_title('温度变化趋势', fontsize=14, fontweight='bold', pad=15)
        ax2.set_ylabel('温度 (°C)', fontsize=12)
        ax2.legend(loc='upper right')
        
        # 绘制电压图
        ax3.plot(range(len(times)), voltages, '-g', label='电压(V)', linewidth=1)
        ax3.set_title('电压变化趋势', fontsize=14, fontweight='bold', pad=15)
        ax3.set_xlabel('时间', fontsize=12)
        ax3.set_ylabel('电压 (V)', fontsize=12)
        ax3.legend(loc='upper right')
        
        # 设置 x 轴标签
        for ax in [ax1, ax2, ax3]:
            num_points = len(times)
            step = max(1, num_points // 10)
            ax.set_xticks(range(0, num_points, step))
            ax.set_xticklabels(
                [times[i] for i in range(0, num_points, step)],
                rotation=45
            )
        
        plt.tight_layout()
        
        # 将图表转换为 base64 字符串
        buffer = BytesIO()
        plt.savefig(buffer, format='png', dpi=100, bbox_inches='tight')
        buffer.seek(0)
        image_png = buffer.getvalue()
        buffer.close()
        plt.close()
        
        # 计算统计数据
        stats = self._calculate_statistics(
            currents, temperatures, voltages, charging_states
        )
        
        logger.info("图表生成完成")
        
        return {
            'graph': base64.b64encode(image_png).decode('utf-8'),
            'stats': stats
        }
    
    def _calculate_statistics(
        self,
        currents: List[float],
        temperatures: List[float],
        voltages: List[float],
        charging_states: List[int]
    ) -> Dict:
        """计算统计数据"""
        # 统计各充电状态出现次数
        charge_state_counts = {
            'no_charge': sum(1 for state in charging_states if state == 0),      # 停充
            'discharge': sum(1 for state in charging_states if state == 1),      # 放电
            'precharge': sum(1 for state in charging_states if state == 2),      # 预充电
            'cc_charge': sum(1 for state in charging_states if state == 3),      # CC恒流充电
            'cv_charge': sum(1 for state in charging_states if state == 4),      # CV恒压充电
            'full': sum(1 for state in charging_states if state == 5),           # 充满
            'done': sum(1 for state in charging_states if state == 6),           # 充电完成
            'fault': sum(1 for state in charging_states if state == 7),          # 充电错误
        }
        
        return {
            'total_points': len(currents),
            'avg_current': sum(currents) / len(currents) if currents else 0,
            'max_current': max(currents) if currents else 0,
            'min_current': min(currents) if currents else 0,
            'avg_temp': sum(temperatures) / len(temperatures) if temperatures else 0,
            'max_temp': max(temperatures) if temperatures else 0,
            'min_temp': min(temperatures) if temperatures else 0,
            'avg_voltage': sum(voltages) / len(voltages) if voltages else 0,
            'charge_state_counts': charge_state_counts,
        }
