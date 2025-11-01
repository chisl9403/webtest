"""
Matplotlib 配置工具
"""
import matplotlib
matplotlib.use('Agg')  # 设置无界面后端
import matplotlib.pyplot as plt
import platform
import logging

logger = logging.getLogger(__name__)

def setup_matplotlib():
    """配置 matplotlib 的中文字体支持"""
    
    # 根据操作系统配置字体
    if platform.system() == 'Darwin':  # macOS
        plt.rcParams['font.sans-serif'] = [
            'Arial Unicode MS',
            'Hiragino Sans GB',
            'Heiti TC',
            'STHeiti',
            'PingFang SC',
            'Songti SC'
        ]
    elif platform.system() == 'Windows':
        plt.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei']
    else:  # Linux
        plt.rcParams['font.sans-serif'] = [
            'WenQuanYi Micro Hei',
            'Noto Sans CJK SC',
            'DejaVu Sans'
        ]
    
    # 用来正常显示负号
    plt.rcParams['axes.unicode_minus'] = False
    
    logger.info(f"matplotlib 字体设置: {plt.rcParams['font.sans-serif']}")
    
    # 验证可用字体
    try:
        import matplotlib.font_manager as fm
        available_fonts = [f.name for f in fm.fontManager.ttflist]
        logger.info(f"系统可用字体数量: {len(available_fonts)}")
        
        # 检查推荐字体是否可用
        test_fonts = ['Arial Unicode MS', 'Hiragino Sans GB', 'STHeiti']
        for font in test_fonts:
            if font in available_fonts:
                logger.info(f"✓ 找到推荐字体: {font}")
    except Exception as e:
        logger.warning(f"字体检查失败: {str(e)}")
