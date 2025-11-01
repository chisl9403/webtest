<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { Upload, DocumentChecked, TrendCharts, InfoFilled, DataAnalysis } from '@element-plus/icons-vue'
import type { UploadFile, UploadRawFile } from 'element-plus'
import * as echarts from 'echarts'

// API 配置
// 使用相对路径 /api，让 Vite 代理转发到后端
// 这样在局域网访问时也能正常工作
const API_URL = '/api'

// 响应式数据
const fileList = ref<UploadFile[]>([])
const uploading = ref(false)
const analyzing = ref(false)
const uploadProgress = ref(0)
const analysisResults = ref<any>(null)
const chartData = ref<any>(null)
const currentChart = ref<any>(null)
const temperatureChart = ref<any>(null)
const voltageChart = ref<any>(null)
const chargeStateChart = ref<any>(null)
const expandedChart = ref<string | null>(null) // 'current', 'temperature', 'voltage', 'chargeState', null
const fullscreenChart = ref<HTMLElement | null>(null) // 全屏的图表元素
const fullscreenChartType = ref<string | null>(null) // 当前全屏的图表类型
const showUsageTips = ref<string[]>(['usage']) // 控制使用提示的折叠状态
const showStatsCards = ref<string[]>(['stats']) // 控制统计卡片的折叠状态

// 电流单位自动转换函数
const formatCurrent = (valueInMicroAmps: number): { value: number; unit: string } => {
  const absValue = Math.abs(valueInMicroAmps)
  
  if (absValue >= 1000000) {
    // >= 1,000,000 μA = >= 1 A，使用 A
    return {
      value: parseFloat((valueInMicroAmps / 1000000).toFixed(2)),
      unit: 'A'
    }
  } else if (absValue >= 1000) {
    // >= 1,000 μA = >= 1 mA，使用 mA
    return {
      value: parseFloat((valueInMicroAmps / 1000).toFixed(2)),
      unit: 'mA'
    }
  } else {
    // < 1,000 μA，使用 μA
    return {
      value: parseFloat(valueInMicroAmps.toFixed(2)),
      unit: 'μA'
    }
  }
}

// 获取电流数据的合适单位（基于数据范围）
const getBestCurrentUnit = (values: number[]): { divisor: number; unit: string } => {
  if (!values || values.length === 0) {
    return { divisor: 1, unit: 'μA' }
  }
  
  const maxValue = Math.max(...values.map(v => Math.abs(v)))
  
  if (maxValue >= 1000000) {
    return { divisor: 1000000, unit: 'A' }
  } else if (maxValue >= 1000) {
    return { divisor: 1000, unit: 'mA' }
  } else {
    return { divisor: 1, unit: 'μA' }
  }
}

// 充电状态映射
const chargeStateMap: Record<number, { name: string; color: string }> = {
  0: { name: '停充', color: '#909399' },      // 灰色
  1: { name: '放电', color: '#F56C6C' },      // 红色
  2: { name: '预充电', color: '#E6A23C' },    // 橙色
  3: { name: 'CC恒流', color: '#409EFF' },    // 蓝色
  4: { name: 'CV恒压', color: '#67C23A' },    // 绿色
  5: { name: '充满', color: '#95F204' },      // 亮绿
  6: { name: '完成', color: '#00D084' },      // 青色
  7: { name: '错误', color: '#FF0000' }       // 亮红
}

// 获取充电状态名称
const getChargeStateName = (state: number): string => {
  return chargeStateMap[state]?.name || '未知'
}

// 获取充电状态颜色
const getChargeStateColor = (state: number): string => {
  return chargeStateMap[state]?.color || '#909399'
}

// 统计数据
interface StatsData {
  total_points: number
  avg_current: number
  max_current: number
  min_current: number
  avg_temp: number
  charge_state_counts: {
    no_charge: number
    discharge: number
    precharge: number
    cc_charge: number
    cv_charge: number
    full: number
    done: number
    fault: number
  }
}

// 文件上传前的验证
const beforeUpload = (rawFile: UploadRawFile) => {
  // 检查文件类型
  if (!rawFile.name.toLowerCase().endsWith('.log')) {
    ElMessage.error('请选择 .log 格式的日志文件')
    return false
  }

  // 检查文件大小（限制为 30MB）
  const maxSize = 30 * 1024 * 1024
  if (rawFile.size > maxSize) {
    ElMessage.error('文件大小超过限制（最大 30MB）')
    return false
  }

  return true
}

// 文件选择改变
const handleFileChange = (file: UploadFile) => {
  fileList.value = [file]
}

// 文件移除
const handleRemove = () => {
  fileList.value = []
  analysisResults.value = null
  chartData.value = null
  uploadProgress.value = 0
  if (currentChart.value) {
    currentChart.value.dispose()
    currentChart.value = null
  }
  if (temperatureChart.value) {
    temperatureChart.value.dispose()
    temperatureChart.value = null
  }
  if (voltageChart.value) {
    voltageChart.value.dispose()
    voltageChart.value = null
  }
}

// 初始化电流图表
const initCurrentChart = async () => {
  await nextTick()
  
  // 额外延迟确保 DOM 完全渲染
  await new Promise(resolve => setTimeout(resolve, 100))
  
  const chartDom = document.getElementById('currentChart')
  if (!chartDom || !chartData.value) {
    console.error('图表容器未找到或数据为空')
    return
  }
  
  // 确保容器有尺寸
  if (chartDom.offsetWidth === 0 || chartDom.offsetHeight === 0) {
    console.error('图表容器尺寸为0')
    return
  }

  if (currentChart.value) {
    currentChart.value.dispose()
    currentChart.value = null
  }

  currentChart.value = echarts.init(chartDom)

  const { times, currents } = chartData.value
  
  // 数据验证
  if (!times || !currents || times.length === 0 || currents.length === 0) {
    console.error('电流数据为空')
    return
  }

  // 根据电流数据范围自动选择单位
  const { divisor, unit } = getBestCurrentUnit(currents)
  const convertedCurrents = currents.map((v: number) => parseFloat((v / divisor).toFixed(2)))

  const option = {
    title: {
      text: '电流变化趋势',
      left: 'center',
      textStyle: {
        fontSize: 16,
        fontWeight: 'bold'
      }
    },
    tooltip: {
      trigger: 'axis',
      confine: true,
      axisPointer: {
        type: 'cross'
      },
      formatter: (params: any) => {
        const param = params[0]
        return `<div style="font-size: 12px; padding: 4px;">
          <strong>时间:</strong> ${param.axisValue}<br/>
          <strong>电流:</strong> ${param.value} ${unit}
        </div>`
      }
    },
    grid: {
      left: '8%',
      right: '5%',
      top: '15%',
      bottom: '18%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: times,
      axisLabel: { 
        rotate: 45,
        interval: Math.floor(times.length / 10)
      },
      name: '时间',
      nameLocation: 'center',
      nameGap: 35
    },
    yAxis: {
      type: 'value',
      name: `电流 (${unit})`,
      nameLocation: 'center',
      nameGap: 50
    },
    dataZoom: [
      // X轴 - inside 缩放
      {
        type: 'inside',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: true,
        moveOnMouseMove: false,
        moveOnMouseWheel: false,
        preventDefaultMouseMove: true,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100,
        disabled: false
      },
      // X轴 - slider 滑块
      {
        type: 'slider',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        bottom: 5,
        left: '10%',
        right: '10%',
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        height: 25,
        borderColor: '#409EFF',
        fillerColor: 'rgba(64, 158, 255, 0.2)',
        handleSize: '120%',
        handleStyle: {
          color: '#409EFF',
          borderColor: '#409EFF'
        },
        textStyle: {
          color: '#606266',
          fontSize: 12
        },
        brushSelect: false,
        labelFormatter: (value: number, valueStr: string) => {
          const index = Math.floor((value / 100) * times.length)
          return times[index] || valueStr
        },
        dataBackground: {
          lineStyle: {
            color: '#409EFF',
            opacity: 0.5,
            width: 1
          },
          areaStyle: {
            color: 'rgba(64, 158, 255, 0.2)',
            opacity: 0.5
          }
        }
      },
      // Y轴 - inside 缩放
      {
        type: 'inside',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: false,  // Y轴不使用滚轮，避免冲突
        moveOnMouseMove: false,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100
      },
      // Y轴 - slider 滑块
      {
        type: 'slider',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        left: 5,
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        width: 20,
        borderColor: '#409EFF',
        fillerColor: 'rgba(64, 158, 255, 0.15)',
        handleSize: '120%',
        handleStyle: {
          color: '#409EFF',
          borderColor: '#409EFF'
        },
        textStyle: {
          color: '#606266',
          fontSize: 10
        },
        brushSelect: false,
        dataBackground: {
          lineStyle: {
            color: '#409EFF',
            opacity: 0.4,
            width: 1
          },
          areaStyle: {
            color: 'rgba(64, 158, 255, 0.15)',
            opacity: 0.4
          }
        }
      }
    ],
    series: [{
      name: '电流',
      type: 'line',
      data: convertedCurrents,
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      xAxisIndex: 0,  // 明确绑定到第一个 x 轴
      yAxisIndex: 0,  // 明确绑定到第一个 y 轴
      lineStyle: { color: '#409EFF', width: 3 },
      itemStyle: { color: '#409EFF' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(64, 158, 255, 0.4)' },
          { offset: 1, color: 'rgba(64, 158, 255, 0.1)' }
        ])
      }
    }]
  }

  currentChart.value.setOption(option, true)
  console.log('✅ 电流图表配置已设置，dataZoom配置:', {
    inside: option.dataZoom[0],
    slider: {
      type: option.dataZoom[1].type,
      bottom: option.dataZoom[1].bottom,
      height: option.dataZoom[1].height,
      start: option.dataZoom[1].start,
      end: option.dataZoom[1].end
    }
  })
  
  // 定义缩放范围变量
  let currentStart = 0
  let currentEnd = 100
  let currentYStart = 0  // Y轴起始位置
  let currentYEnd = 100  // Y轴结束位置
  
  // 添加缩放事件监听，同步更新变量
  currentChart.value.on('dataZoom', (params: any) => {
    console.log('📊 [电流图表] dataZoom 事件触发 - 完整参数:', params)
    
    const oldStart = currentStart
    const oldEnd = currentEnd
    
    // ECharts dataZoom 事件可能有多种参数结构，需要兼容处理
    if (params.batch && params.batch[0]) {
      // 批量操作模式
      currentStart = params.batch[0].start !== undefined ? params.batch[0].start : currentStart
      currentEnd = params.batch[0].end !== undefined ? params.batch[0].end : currentEnd
    } else if (params.start !== undefined && params.end !== undefined) {
      // 直接参数模式
      currentStart = params.start
      currentEnd = params.end
    } else {
      // 从图表实例获取当前 dataZoom 配置
      const option = currentChart.value.getOption()
      if (option.dataZoom && option.dataZoom[0]) {
        currentStart = option.dataZoom[0].start !== undefined ? option.dataZoom[0].start : currentStart
        currentEnd = option.dataZoom[0].end !== undefined ? option.dataZoom[0].end : currentEnd
      }
    }
    
    // 计算数据索引范围
    const totalPoints = chartData.value?.times.length || 0
    const startIndex = Math.floor((currentStart / 100) * totalPoints)
    const endIndex = Math.floor((currentEnd / 100) * totalPoints)
    const startTime = chartData.value?.times[startIndex] || '未知'
    const endTime = chartData.value?.times[endIndex - 1] || '未知'
    
    console.log('🔄 [电流图表] 显示区域同步更新:', {
      变化前: { start: oldStart.toFixed(2), end: oldEnd.toFixed(2) },
      变化后: { start: currentStart.toFixed(2), end: currentEnd.toFixed(2) },
      显示范围: `${currentStart.toFixed(1)}% - ${currentEnd.toFixed(1)}%`,
      数据索引范围: `[${startIndex}, ${endIndex})`,
      时间范围: `${startTime} → ${endTime}`,
      总数据点数: totalPoints,
      实际显示点数: endIndex - startIndex,
      '✅ 图表与滑块对齐': '中心对齐，显示相同时间范围'
    })
  })
  
  // 监听鼠标滚轮事件
  const currentChartDom = document.getElementById('currentChart')
  if (currentChartDom) {
    currentChartDom.addEventListener('wheel', (e) => {
      e.preventDefault()
      
      const zoomIntensity = 0.1 // 每次缩放10%
      
      // 判断是否按下Ctrl键
      if (e.ctrlKey || e.metaKey) {
        // Ctrl + 滚轮：缩放Y轴
        const oldYStart = currentYStart
        const oldYEnd = currentYEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，Y轴放大
          const span = currentYEnd - currentYStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (currentYStart + currentYEnd) / 2
          currentYStart = center - newSpan / 2
          currentYEnd = center + newSpan / 2
        } else {
          // 向下滚动，Y轴缩小
          const span = currentYEnd - currentYStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (currentYStart + currentYEnd) / 2
          currentYStart = Math.max(0, center - newSpan / 2)
          currentYEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [电流图表] Ctrl+滚轮 Y轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldYStart.toFixed(1)}% - ${oldYEnd.toFixed(1)}%`,
          缩放后: `${currentYStart.toFixed(1)}% - ${currentYEnd.toFixed(1)}%`,
          显示范围: `${(currentYEnd - currentYStart).toFixed(1)}%`
        })
        
        // 更新Y轴
        currentChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [2, 3],  // Y轴的inside和slider
          start: currentYStart,
          end: currentYEnd
        })
      } else {
        // 普通滚轮：缩放X轴
        const oldStart = currentStart
        const oldEnd = currentEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，X轴放大
          const span = currentEnd - currentStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (currentStart + currentEnd) / 2
          currentStart = center - newSpan / 2
          currentEnd = center + newSpan / 2
        } else {
          // 向下滚动，X轴缩小
          const span = currentEnd - currentStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (currentStart + currentEnd) / 2
          currentStart = Math.max(0, center - newSpan / 2)
          currentEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [电流图表] 滚轮 X轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldStart.toFixed(1)}% - ${oldEnd.toFixed(1)}%`,
          缩放后: `${currentStart.toFixed(1)}% - ${currentEnd.toFixed(1)}%`,
          显示范围: `${(currentEnd - currentStart).toFixed(1)}%`
        })
        
        // 更新X轴
        currentChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [0, 1],  // X轴的inside和slider
          start: currentStart,
          end: currentEnd
        })
      }
    }, { passive: false })
    
    // 添加鼠标拖动功能
    let isDragging = false
    let dragStartX = 0
    let dragStartPercent = 0
    
    currentChartDom.addEventListener('mousedown', (e) => {
      // 只在图表区域内启用拖动，避免与其他交互冲突
      if (e.button === 0) {  // 左键
        isDragging = true
        dragStartX = e.clientX
        dragStartPercent = currentStart
        currentChartDom.style.cursor = 'grabbing'
        console.log('🖱️ [电流图表] 开始拖动')
      }
    })
    
    currentChartDom.addEventListener('mousemove', (e) => {
      if (!isDragging) return
      
      const deltaX = e.clientX - dragStartX
      const chartWidth = currentChartDom.offsetWidth
      const percentDelta = (deltaX / chartWidth) * 100
      
      const span = currentEnd - currentStart
      let newStart = dragStartPercent + percentDelta  // 修正：改为加号，向右拖显示后面的数据
      let newEnd = newStart + span
      
      // 边界检查
      if (newStart < 0) {
        newStart = 0
        newEnd = span
      }
      if (newEnd > 100) {
        newEnd = 100
        newStart = 100 - span
      }
      
      currentStart = newStart
      currentEnd = newEnd
      
      currentChart.value.dispatchAction({
        type: 'dataZoom',
        dataZoomIndex: [0, 1, 2, 3],
        start: currentStart,
        end: currentEnd
      })
    })
    
    currentChartDom.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false
        currentChartDom.style.cursor = 'grab'
        console.log('🖱️ [电流图表] 结束拖动，当前范围:', `${currentStart.toFixed(1)}% - ${currentEnd.toFixed(1)}%`)
      }
    })
    
    currentChartDom.addEventListener('mouseleave', () => {
      if (isDragging) {
        isDragging = false
        currentChartDom.style.cursor = 'grab'
      }
    })
    
    // 设置默认鼠标样式
    currentChartDom.style.cursor = 'grab'
  }
  
  console.log('电流图表初始化完成，dataZoom配置:', option.dataZoom)
}

// 初始化温度图表
const initTemperatureChart = async () => {
  await nextTick()
  
  // 额外延迟确保 DOM 完全渲染
  await new Promise(resolve => setTimeout(resolve, 100))
  
  const chartDom = document.getElementById('temperatureChart')
  if (!chartDom || !chartData.value) {
    console.error('温度图表容器未找到或数据为空')
    return
  }
  
  // 确保容器有尺寸
  if (chartDom.offsetWidth === 0 || chartDom.offsetHeight === 0) {
    console.error('温度图表容器尺寸为0')
    return
  }

  if (temperatureChart.value) {
    temperatureChart.value.dispose()
    temperatureChart.value = null
  }

  temperatureChart.value = echarts.init(chartDom)

  const { times, temperatures } = chartData.value
  
  // 数据验证
  if (!times || !temperatures || times.length === 0 || temperatures.length === 0) {
    console.error('温度数据为空')
    return
  }

  const option = {
    title: {
      text: '温度变化趋势',
      left: 'center',
      textStyle: {
        fontSize: 16,
        fontWeight: 'bold'
      }
    },
    tooltip: {
      trigger: 'axis',
      confine: true,
      axisPointer: {
        type: 'cross'
      },
      formatter: (params: any) => {
        const param = params[0]
        return `<div style="font-size: 12px; padding: 4px;">
          <strong>时间:</strong> ${param.axisValue}<br/>
          <strong>温度:</strong> ${param.value} °C
        </div>`
      }
    },
    grid: {
      left: '8%',
      right: '5%',
      top: '15%',
      bottom: '18%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: times,
      axisLabel: { 
        rotate: 45,
        interval: Math.floor(times.length / 10)
      },
      name: '时间',
      nameLocation: 'center',
      nameGap: 35
    },
    yAxis: {
      type: 'value',
      name: '温度 (°C)',
      nameLocation: 'center',
      nameGap: 50
    },
    dataZoom: [
      // X轴 - inside 缩放
      {
        type: 'inside',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: true,
        moveOnMouseMove: false,
        moveOnMouseWheel: false,
        preventDefaultMouseMove: true,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100,
        disabled: false
      },
      // X轴 - slider 滑块
      {
        type: 'slider',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        bottom: 5,
        left: '10%',
        right: '10%',
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        height: 25,
        borderColor: '#F56C6C',
        fillerColor: 'rgba(245, 108, 108, 0.2)',
        handleSize: '120%',
        handleStyle: {
          color: '#F56C6C',
          borderColor: '#F56C6C'
        },
        textStyle: {
          color: '#606266',
          fontSize: 12
        },
        brushSelect: false,
        labelFormatter: (value: number, valueStr: string) => {
          const index = Math.floor((value / 100) * times.length)
          return times[index] || valueStr
        },
        dataBackground: {
          lineStyle: {
            color: '#F56C6C',
            opacity: 0.5,
            width: 1
          },
          areaStyle: {
            color: 'rgba(245, 108, 108, 0.2)',
            opacity: 0.5
          }
        }
      },
      // Y轴 - inside 缩放
      {
        type: 'inside',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: false,
        moveOnMouseMove: false,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100
      },
      // Y轴 - slider 滑块
      {
        type: 'slider',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        left: 5,
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        width: 20,
        borderColor: '#F56C6C',
        fillerColor: 'rgba(245, 108, 108, 0.15)',
        handleSize: '120%',
        handleStyle: {
          color: '#F56C6C',
          borderColor: '#F56C6C'
        },
        textStyle: {
          color: '#606266',
          fontSize: 10
        },
        brushSelect: false,
        dataBackground: {
          lineStyle: {
            color: '#F56C6C',
            opacity: 0.4,
            width: 1
          },
          areaStyle: {
            color: 'rgba(245, 108, 108, 0.15)',
            opacity: 0.4
          }
        }
      }
    ],
    series: [{
      name: '温度',
      type: 'line',
      data: temperatures,
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      xAxisIndex: 0,  // 明确绑定到第一个 x 轴
      yAxisIndex: 0,  // 明确绑定到第一个 y 轴
      lineStyle: { color: '#F56C6C', width: 3 },
      itemStyle: { color: '#F56C6C' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(245, 108, 108, 0.4)' },
          { offset: 1, color: 'rgba(245, 108, 108, 0.1)' }
        ])
      }
    }]
  }

  temperatureChart.value.setOption(option, true)
  console.log('✅ 温度图表配置已设置，dataZoom配置:', {
    inside: option.dataZoom[0],
    slider: {
      type: option.dataZoom[1].type,
      bottom: option.dataZoom[1].bottom,
      height: option.dataZoom[1].height,
      borderColor: option.dataZoom[1].borderColor
    }
  })
  
  // 定义缩放范围变量
  let tempStart = 0
  let tempEnd = 100
  let tempYStart = 0  // Y轴起始位置
  let tempYEnd = 100  // Y轴结束位置
  
  // 添加缩放事件监听，同步更新变量
  temperatureChart.value.on('dataZoom', (params: any) => {
    console.log('📊 [温度图表] dataZoom 事件触发 - 完整参数:', params)
    
    const oldStart = tempStart
    const oldEnd = tempEnd
    
    // ECharts dataZoom 事件可能有多种参数结构，需要兼容处理
    if (params.batch && params.batch[0]) {
      tempStart = params.batch[0].start !== undefined ? params.batch[0].start : tempStart
      tempEnd = params.batch[0].end !== undefined ? params.batch[0].end : tempEnd
    } else if (params.start !== undefined && params.end !== undefined) {
      tempStart = params.start
      tempEnd = params.end
    } else {
      const option = temperatureChart.value.getOption()
      if (option.dataZoom && option.dataZoom[0]) {
        tempStart = option.dataZoom[0].start !== undefined ? option.dataZoom[0].start : tempStart
        tempEnd = option.dataZoom[0].end !== undefined ? option.dataZoom[0].end : tempEnd
      }
    }
    
    const totalPoints = chartData.value?.times.length || 0
    const startIndex = Math.floor((tempStart / 100) * totalPoints)
    const endIndex = Math.floor((tempEnd / 100) * totalPoints)
    const startTime = chartData.value?.times[startIndex] || '未知'
    const endTime = chartData.value?.times[endIndex - 1] || '未知'
    
    console.log('🔄 [温度图表] 显示区域同步更新:', {
      变化前: { start: oldStart.toFixed(2), end: oldEnd.toFixed(2) },
      变化后: { start: tempStart.toFixed(2), end: tempEnd.toFixed(2) },
      显示范围: `${tempStart.toFixed(1)}% - ${tempEnd.toFixed(1)}%`,
      数据索引范围: `[${startIndex}, ${endIndex})`,
      时间范围: `${startTime} → ${endTime}`,
      实际显示点数: endIndex - startIndex
    })
  })
  
  // 监听鼠标滚轮事件
  const tempChartDom = document.getElementById('temperatureChart')
  if (tempChartDom) {
    tempChartDom.addEventListener('wheel', (e) => {
      e.preventDefault()
      
      const zoomIntensity = 0.1 // 每次缩放10%
      
      // 判断是否按下Ctrl键
      if (e.ctrlKey || e.metaKey) {
        // Ctrl + 滚轮：缩放Y轴
        const oldYStart = tempYStart
        const oldYEnd = tempYEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，Y轴放大
          const span = tempYEnd - tempYStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (tempYStart + tempYEnd) / 2
          tempYStart = center - newSpan / 2
          tempYEnd = center + newSpan / 2
        } else {
          // 向下滚动，Y轴缩小
          const span = tempYEnd - tempYStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (tempYStart + tempYEnd) / 2
          tempYStart = Math.max(0, center - newSpan / 2)
          tempYEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [温度图表] Ctrl+滚轮 Y轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldYStart.toFixed(1)}% - ${oldYEnd.toFixed(1)}%`,
          缩放后: `${tempYStart.toFixed(1)}% - ${tempYEnd.toFixed(1)}%`,
          显示范围: `${(tempYEnd - tempYStart).toFixed(1)}%`
        })
        
        // 更新Y轴
        temperatureChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [2, 3],  // Y轴的inside和slider
          start: tempYStart,
          end: tempYEnd
        })
      } else {
        // 普通滚轮：缩放X轴
        const oldStart = tempStart
        const oldEnd = tempEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，X轴放大
          const span = tempEnd - tempStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (tempStart + tempEnd) / 2
          tempStart = center - newSpan / 2
          tempEnd = center + newSpan / 2
        } else {
          // 向下滚动，X轴缩小
          const span = tempEnd - tempStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (tempStart + tempEnd) / 2
          tempStart = Math.max(0, center - newSpan / 2)
          tempEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [温度图表] 滚轮 X轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldStart.toFixed(1)}% - ${oldEnd.toFixed(1)}%`,
          缩放后: `${tempStart.toFixed(1)}% - ${tempEnd.toFixed(1)}%`,
          显示范围: `${(tempEnd - tempStart).toFixed(1)}%`
        })
        
        // 更新X轴
        temperatureChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [0, 1],  // X轴的inside和slider
          start: tempStart,
          end: tempEnd
        })
      }
    }, { passive: false })
    
    // 添加鼠标拖动功能
    let isDragging = false
    let dragStartX = 0
    let dragStartPercent = 0
    
    tempChartDom.addEventListener('mousedown', (e) => {
      if (e.button === 0) {
        isDragging = true
        dragStartX = e.clientX
        dragStartPercent = tempStart
        tempChartDom.style.cursor = 'grabbing'
        console.log('🖱️ [温度图表] 开始拖动')
      }
    })
    
    tempChartDom.addEventListener('mousemove', (e) => {
      if (!isDragging) return
      
      const deltaX = e.clientX - dragStartX
      const chartWidth = tempChartDom.offsetWidth
      const percentDelta = (deltaX / chartWidth) * 100
      
      const span = tempEnd - tempStart
      let newStart = dragStartPercent + percentDelta  // 修正：改为加号
      let newEnd = newStart + span
      
      if (newStart < 0) {
        newStart = 0
        newEnd = span
      }
      if (newEnd > 100) {
        newEnd = 100
        newStart = 100 - span
      }
      
      tempStart = newStart
      tempEnd = newEnd
      
      temperatureChart.value.dispatchAction({
        type: 'dataZoom',
        dataZoomIndex: [0, 1, 2, 3],
        start: tempStart,
        end: tempEnd
      })
    })
    
    tempChartDom.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false
        tempChartDom.style.cursor = 'grab'
        console.log('🖱️ [温度图表] 结束拖动，当前范围:', `${tempStart.toFixed(1)}% - ${tempEnd.toFixed(1)}%`)
      }
    })
    
    tempChartDom.addEventListener('mouseleave', () => {
      if (isDragging) {
        isDragging = false
        tempChartDom.style.cursor = 'grab'
      }
    })
    
    tempChartDom.style.cursor = 'grab'
  }
  
  console.log('温度图表初始化完成')
}

// 初始化电压图表
const initVoltageChart = async () => {
  await nextTick()
  
  // 额外延迟确保 DOM 完全渲染
  await new Promise(resolve => setTimeout(resolve, 100))
  
  const chartDom = document.getElementById('voltageChart')
  if (!chartDom || !chartData.value) {
    console.error('电压图表容器未找到或数据为空')
    return
  }
  
  // 确保容器有尺寸
  if (chartDom.offsetWidth === 0 || chartDom.offsetHeight === 0) {
    console.error('电压图表容器尺寸为0')
    return
  }

  if (voltageChart.value) {
    voltageChart.value.dispose()
    voltageChart.value = null
  }

  voltageChart.value = echarts.init(chartDom)

  const { times, voltages } = chartData.value
  
  // 数据验证
  if (!times || !voltages || times.length === 0 || voltages.length === 0) {
    console.error('电压数据为空')
    return
  }

  const option = {
    title: {
      text: '电压变化趋势',
      left: 'center',
      textStyle: {
        fontSize: 16,
        fontWeight: 'bold'
      }
    },
    tooltip: {
      trigger: 'axis',
      confine: true,
      axisPointer: {
        type: 'cross'
      },
      formatter: (params: any) => {
        const param = params[0]
        return `<div style="font-size: 12px; padding: 4px;">
          <strong>时间:</strong> ${param.axisValue}<br/>
          <strong>电压:</strong> ${param.value} V
        </div>`
      }
    },
    grid: {
      left: '8%',
      right: '5%',
      top: '15%',
      bottom: '18%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: times,
      axisLabel: { 
        rotate: 45,
        interval: Math.floor(times.length / 10)
      },
      name: '时间',
      nameLocation: 'center',
      nameGap: 35
    },
    yAxis: {
      type: 'value',
      name: '电压 (V)',
      nameLocation: 'center',
      nameGap: 50
    },
    dataZoom: [
      // X轴 - inside 缩放
      {
        type: 'inside',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: true,
        moveOnMouseMove: false,
        moveOnMouseWheel: false,
        preventDefaultMouseMove: true,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100,
        disabled: false
      },
      // X轴 - slider 滑块
      {
        type: 'slider',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        bottom: 5,
        left: '10%',
        right: '10%',
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        height: 25,
        borderColor: '#67C23A',
        fillerColor: 'rgba(103, 194, 58, 0.2)',
        handleSize: '120%',
        handleStyle: {
          color: '#67C23A',
          borderColor: '#67C23A'
        },
        textStyle: {
          color: '#606266',
          fontSize: 12
        },
        brushSelect: false,
        labelFormatter: (value: number, valueStr: string) => {
          const index = Math.floor((value / 100) * times.length)
          return times[index] || valueStr
        },
        dataBackground: {
          lineStyle: {
            color: '#67C23A',
            opacity: 0.5,
            width: 1
          },
          areaStyle: {
            color: 'rgba(103, 194, 58, 0.2)',
            opacity: 0.5
          }
        }
      },
      // Y轴 - inside 缩放
      {
        type: 'inside',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: false,
        moveOnMouseMove: false,
        zoomLock: false,
        throttle: 50,
        minSpan: 5,
        maxSpan: 100
      },
      // Y轴 - slider 滑块
      {
        type: 'slider',
        yAxisIndex: 0,
        start: 0,
        end: 100,
        left: 5,
        showDetail: true,
        showDataShadow: true,
        realtime: true,
        zoomLock: false,
        width: 20,
        borderColor: '#67C23A',
        fillerColor: 'rgba(103, 194, 58, 0.15)',
        handleSize: '120%',
        handleStyle: {
          color: '#67C23A',
          borderColor: '#67C23A'
        },
        textStyle: {
          color: '#606266',
          fontSize: 10
        },
        brushSelect: false,
        dataBackground: {
          lineStyle: {
            color: '#67C23A',
            opacity: 0.4,
            width: 1
          },
          areaStyle: {
            color: 'rgba(103, 194, 58, 0.15)',
            opacity: 0.4
          }
        }
      }
    ],
    series: [{
      name: '电压',
      type: 'line',
      data: voltages,
      smooth: true,
      symbol: 'circle',
      symbolSize: 6,
      xAxisIndex: 0,  // 明确绑定到第一个 x 轴
      yAxisIndex: 0,  // 明确绑定到第一个 y 轴
      lineStyle: { color: '#67C23A', width: 3 },
      itemStyle: { color: '#67C23A' },
      areaStyle: {
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: 'rgba(103, 194, 58, 0.4)' },
          { offset: 1, color: 'rgba(103, 194, 58, 0.1)' }
        ])
      }
    }]
  }

  voltageChart.value.setOption(option, true)
  console.log('✅ 电压图表配置已设置，dataZoom配置:', {
    inside: option.dataZoom[0],
    slider: {
      type: option.dataZoom[1].type,
      bottom: option.dataZoom[1].bottom,
      height: option.dataZoom[1].height,
      borderColor: option.dataZoom[1].borderColor
    }
  })
  
  // 定义缩放范围变量
  let voltStart = 0
  let voltEnd = 100
  let voltYStart = 0  // Y轴起始位置
  let voltYEnd = 100  // Y轴结束位置
  
  // 添加缩放事件监听，同步更新变量
  voltageChart.value.on('dataZoom', (params: any) => {
    console.log('📊 [电压图表] dataZoom 事件触发 - 完整参数:', params)
    
    const oldStart = voltStart
    const oldEnd = voltEnd
    
    // ECharts dataZoom 事件可能有多种参数结构，需要兼容处理
    if (params.batch && params.batch[0]) {
      voltStart = params.batch[0].start !== undefined ? params.batch[0].start : voltStart
      voltEnd = params.batch[0].end !== undefined ? params.batch[0].end : voltEnd
    } else if (params.start !== undefined && params.end !== undefined) {
      voltStart = params.start
      voltEnd = params.end
    } else {
      const option = voltageChart.value.getOption()
      if (option.dataZoom && option.dataZoom[0]) {
        voltStart = option.dataZoom[0].start !== undefined ? option.dataZoom[0].start : voltStart
        voltEnd = option.dataZoom[0].end !== undefined ? option.dataZoom[0].end : voltEnd
      }
    }
    
    const totalPoints = chartData.value?.times.length || 0
    const startIndex = Math.floor((voltStart / 100) * totalPoints)
    const endIndex = Math.floor((voltEnd / 100) * totalPoints)
    const startTime = chartData.value?.times[startIndex] || '未知'
    const endTime = chartData.value?.times[endIndex - 1] || '未知'
    
    console.log('🔄 [电压图表] 显示区域同步更新:', {
      变化前: { start: oldStart.toFixed(2), end: oldEnd.toFixed(2) },
      变化后: { start: voltStart.toFixed(2), end: voltEnd.toFixed(2) },
      显示范围: `${voltStart.toFixed(1)}% - ${voltEnd.toFixed(1)}%`,
      数据索引范围: `[${startIndex}, ${endIndex})`,
      时间范围: `${startTime} → ${endTime}`,
      实际显示点数: endIndex - startIndex
    })
  })
  
  // 监听鼠标滚轮事件
  const voltChartDom = document.getElementById('voltageChart')
  if (voltChartDom) {
    voltChartDom.addEventListener('wheel', (e) => {
      e.preventDefault()
      
      const zoomIntensity = 0.1 // 每次缩放10%
      
      // 判断是否按下Ctrl键
      if (e.ctrlKey || e.metaKey) {
        // Ctrl + 滚轮：缩放Y轴
        const oldYStart = voltYStart
        const oldYEnd = voltYEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，Y轴放大
          const span = voltYEnd - voltYStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (voltYStart + voltYEnd) / 2
          voltYStart = center - newSpan / 2
          voltYEnd = center + newSpan / 2
        } else {
          // 向下滚动，Y轴缩小
          const span = voltYEnd - voltYStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (voltYStart + voltYEnd) / 2
          voltYStart = Math.max(0, center - newSpan / 2)
          voltYEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [电压图表] Ctrl+滚轮 Y轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldYStart.toFixed(1)}% - ${oldYEnd.toFixed(1)}%`,
          缩放后: `${voltYStart.toFixed(1)}% - ${voltYEnd.toFixed(1)}%`,
          显示范围: `${(voltYEnd - voltYStart).toFixed(1)}%`
        })
        
        // 更新Y轴
        voltageChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [2, 3],  // Y轴的inside和slider
          start: voltYStart,
          end: voltYEnd
        })
      } else {
        // 普通滚轮：缩放X轴
        const oldStart = voltStart
        const oldEnd = voltEnd
        
        if (e.deltaY < 0) {
          // 向上滚动，X轴放大
          const span = voltEnd - voltStart
          const newSpan = span * (1 - zoomIntensity)
          const center = (voltStart + voltEnd) / 2
          voltStart = center - newSpan / 2
          voltEnd = center + newSpan / 2
        } else {
          // 向下滚动，X轴缩小
          const span = voltEnd - voltStart
          const newSpan = Math.min(100, span * (1 + zoomIntensity))
          const center = (voltStart + voltEnd) / 2
          voltStart = Math.max(0, center - newSpan / 2)
          voltEnd = Math.min(100, center + newSpan / 2)
        }
        
        console.log('🖱️ [电压图表] 滚轮 X轴缩放:', {
          方向: e.deltaY < 0 ? '放大 (↑)' : '缩小 (↓)',
          缩放前: `${oldStart.toFixed(1)}% - ${oldEnd.toFixed(1)}%`,
          缩放后: `${voltStart.toFixed(1)}% - ${voltEnd.toFixed(1)}%`,
          显示范围: `${(voltEnd - voltStart).toFixed(1)}%`
        })
        
        // 更新X轴
        voltageChart.value.dispatchAction({
          type: 'dataZoom',
          dataZoomIndex: [0, 1],  // X轴的inside和slider
          start: voltStart,
          end: voltEnd
        })
      }
    }, { passive: false })
    
    // 添加鼠标拖动功能
    let isDragging = false
    let dragStartX = 0
    let dragStartPercent = 0
    
    voltChartDom.addEventListener('mousedown', (e) => {
      if (e.button === 0) {
        isDragging = true
        dragStartX = e.clientX
        dragStartPercent = voltStart
        voltChartDom.style.cursor = 'grabbing'
        console.log('🖱️ [电压图表] 开始拖动')
      }
    })
    
    voltChartDom.addEventListener('mousemove', (e) => {
      if (!isDragging) return
      
      const deltaX = e.clientX - dragStartX
      const chartWidth = voltChartDom.offsetWidth
      const percentDelta = (deltaX / chartWidth) * 100
      
      const span = voltEnd - voltStart
      let newStart = dragStartPercent + percentDelta  // 修正：改为加号
      let newEnd = newStart + span
      
      if (newStart < 0) {
        newStart = 0
        newEnd = span
      }
      if (newEnd > 100) {
        newEnd = 100
        newStart = 100 - span
      }
      
      voltStart = newStart
      voltEnd = newEnd
      
      voltageChart.value.dispatchAction({
        type: 'dataZoom',
        dataZoomIndex: [0, 1, 2, 3],
        start: voltStart,
        end: voltEnd
      })
    })
    
    voltChartDom.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false
        voltChartDom.style.cursor = 'grab'
        console.log('🖱️ [电压图表] 结束拖动，当前范围:', `${voltStart.toFixed(1)}% - ${voltEnd.toFixed(1)}%`)
      }
    })
    
    voltChartDom.addEventListener('mouseleave', () => {
      if (isDragging) {
        isDragging = false
        voltChartDom.style.cursor = 'grab'
      }
    })
    
    voltChartDom.style.cursor = 'grab'
  }
  
  console.log('电压图表初始化完成')
}

// 响应式调整所有图表
const resizeAllCharts = () => {
  currentChart.value?.resize()
  temperatureChart.value?.resize()
  voltageChart.value?.resize()
  chargeStateChart.value?.resize()
}

// 初始化充电状态图表
const initChargeStateChart = async () => {
  await nextTick()
  
  const chartDom = document.getElementById('chargeStateChart')
  if (!chartDom) {
    console.error('❌ 找不到 chargeStateChart 容器')
    return
  }
  
  if (chargeStateChart.value) {
    chargeStateChart.value.dispose()
  }
  
  chargeStateChart.value = echarts.init(chartDom)
  
  if (!chartData.value?.charge_states) {
    console.error('❌ chartData.charge_states 未定义')
    return
  }
  
  const times = chartData.value.times
  const chargeStates = chartData.value.charge_states
  
  console.log('📊 初始化充电状态图表，数据点数:', chargeStates.length)
  
  const option = {
    title: {
      text: '充电状态',
      left: 'center',
      textStyle: { fontSize: 16, fontWeight: 'bold' }
    },
    tooltip: {
      trigger: 'axis',
      confine: true,
      formatter: (params: any) => {
        const param = params[0]
        const state = chargeStates[param.dataIndex]
        const stateName = getChargeStateName(state)
        const stateColor = getChargeStateColor(state)
        return `<div style="font-size: 12px; padding: 4px;">
                <strong>时间:</strong> ${param.axisValue}<br/>
                <span style="display:inline-block;width:8px;height:8px;background-color:${stateColor};border-radius:50%;margin-right:4px;"></span>
                <strong>状态:</strong> ${stateName} (${state})
                </div>`
      }
    },
    grid: {
      left: '12%',
      right: '8%',
      top: '15%',
      bottom: '25%',
      containLabel: true
    },
    xAxis: [{
      type: 'category',
      data: times,
      boundaryGap: false,
      axisLabel: {
        formatter: (value: string) => value.split(' ')[1] || value,
        fontSize: 10,
        rotate: 45
      },
      name: '时间',
      nameLocation: 'middle',
      nameGap: 45,
      nameTextStyle: { fontSize: 12, fontWeight: 'bold' }
    }],
    yAxis: [{
      type: 'value',
      name: '充电状态',
      nameTextStyle: { fontSize: 12, fontWeight: 'bold' },
      min: -0.5,
      max: 7.5,
      interval: 1,
      axisLabel: {
        formatter: (value: number) => {
          return getChargeStateName(value)
        },
        fontSize: 9
      }
    }],
    toolbox: {
      feature: {
        restore: { title: '还原' },
        saveAsImage: { title: '保存为图片' }
      },
      right: '5%',
      top: '5%'
    },
    dataZoom: [
      {
        type: 'inside',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        zoomOnMouseWheel: true,
        moveOnMouseMove: true,
        moveOnMouseWheel: false
      },
      {
        type: 'slider',
        xAxisIndex: 0,
        start: 0,
        end: 100,
        height: 20,
        bottom: '5%',
        borderColor: '#ccc',
        fillerColor: 'rgba(153, 102, 255, 0.2)',
        handleSize: '80%',
        handleStyle: {
          color: '#9966FF',
          borderColor: '#9966FF'
        },
        textStyle: {
          color: '#606266',
          fontSize: 10
        },
        brushSelect: false,
        dataBackground: {
          lineStyle: {
            color: '#9966FF',
            opacity: 0.4,
            width: 1
          },
          areaStyle: {
            color: 'rgba(153, 102, 255, 0.15)',
            opacity: 0.4
          }
        }
      }
    ],
    series: [{
      name: '充电状态',
      type: 'line',
      data: chargeStates,
      step: 'end',
      symbol: 'circle',
      symbolSize: 4,
      xAxisIndex: 0,
      yAxisIndex: 0,
      lineStyle: { color: '#9966FF', width: 2 },
      itemStyle: {
        color: (params: any) => {
          return getChargeStateColor(params.value)
        }
      }
    }]
  }
  
  chargeStateChart.value.setOption(option, true)
  
  // 定义缩放范围变量
  let chargeStart = 0
  let chargeEnd = 100
  
  // 添加缩放事件监听
  chargeStateChart.value.on('dataZoom', (params: any) => {
    if (params.batch && params.batch[0]) {
      chargeStart = params.batch[0].start !== undefined ? params.batch[0].start : chargeStart
      chargeEnd = params.batch[0].end !== undefined ? params.batch[0].end : chargeEnd
    } else if (params.start !== undefined && params.end !== undefined) {
      chargeStart = params.start
      chargeEnd = params.end
    }
  })
  
  // 监听鼠标滚轮事件
  const chargeChartDom = document.getElementById('chargeStateChart')
  if (chargeChartDom) {
    chargeChartDom.addEventListener('wheel', (e) => {
      if (e.ctrlKey || e.metaKey) {
        e.preventDefault()
        const delta = e.deltaY
        const zoomFactor = delta > 0 ? 1.1 : 0.9
        
        const option = chargeStateChart.value.getOption()
        const yAxis = option.yAxis[0]
        const currentMin = yAxis.min
        const currentMax = yAxis.max
        const range = currentMax - currentMin
        const newRange = range * zoomFactor
        const center = (currentMin + currentMax) / 2
        
        chargeStateChart.value.setOption({
          yAxis: [{
            min: Math.max(-0.5, center - newRange / 2),
            max: Math.min(7.5, center + newRange / 2)
          }]
        })
      }
    }, { passive: false })
  }
}

// 切换图表放大状态
const toggleChartExpand = (chartType: string) => {
  if (expandedChart.value === chartType) {
    expandedChart.value = null
  } else {
    expandedChart.value = chartType
  }
  
  // 延迟调整图表大小以等待 DOM 更新
  setTimeout(() => {
    resizeAllCharts()
  }, 100)
}

// 监听全屏退出事件
const handleFullscreenChange = () => {
  if (!document.fullscreenElement) {
    fullscreenChart.value = null
    fullscreenChartType.value = null
    expandedChart.value = null
    setTimeout(() => {
      resizeAllCharts()
    }, 100)
  }
}

// 切换全屏状态（使用浏览器原生全屏API）
const toggleFullscreen = (chartType: string) => {
  const chartId = chartType === 'current' ? 'currentChart' : 
                  chartType === 'temperature' ? 'temperatureChart' : 
                  chartType === 'voltage' ? 'voltageChart' : 'chargeStateChart'
  const chartElement = document.getElementById(chartId)
  
  if (!chartElement) return
  
  // 检查当前是否已经全屏，且全屏的是当前图表
  if (document.fullscreenElement === chartElement) {
    // 退出全屏
    if (document.exitFullscreen) {
      document.exitFullscreen()
    } else if ((document as any).webkitExitFullscreen) {
      (document as any).webkitExitFullscreen()
    } else if ((document as any).mozCancelFullScreen) {
      (document as any).mozCancelFullScreen()
    } else if ((document as any).msExitFullscreen) {
      (document as any).msExitFullscreen()
    }
    fullscreenChartType.value = null
  } else {
    // 进入全屏
    fullscreenChart.value = chartElement
    fullscreenChartType.value = chartType
    
    if (chartElement.requestFullscreen) {
      chartElement.requestFullscreen()
    } else if ((chartElement as any).webkitRequestFullscreen) {
      (chartElement as any).webkitRequestFullscreen()
    } else if ((chartElement as any).mozRequestFullScreen) {
      (chartElement as any).mozRequestFullScreen()
    } else if ((chartElement as any).msRequestFullscreen) {
      (chartElement as any).msRequestFullscreen()
    }
    
    // 延迟调整图表大小
    setTimeout(() => {
      if (chartType === 'current') {
        currentChart.value?.resize()
      } else if (chartType === 'temperature') {
        temperatureChart.value?.resize()
      } else if (chartType === 'voltage') {
        voltageChart.value?.resize()
      }
    }, 300)
  }
}

// 图表还原功能（合并X轴和Y轴）
const resetChart = (chartType: string) => {
  const chart = chartType === 'current' ? currentChart.value :
                chartType === 'temperature' ? temperatureChart.value :
                chartType === 'voltage' ? voltageChart.value :
                chargeStateChart.value
  
  if (!chart) return
  
  // 还原X轴
  chart.dispatchAction({
    type: 'dataZoom',
    dataZoomIndex: [0, 1], // X轴的inside和slider
    start: 0,
    end: 100
  })
  
  // 还原Y轴
  chart.dispatchAction({
    type: 'dataZoom',
    dataZoomIndex: [2, 3], // Y轴的inside和slider
    start: 0,
    end: 100
  })
  
  const chartName = chartType === 'current' ? '电流' : 
                    chartType === 'temperature' ? '温度' : 
                    chartType === 'voltage' ? '电压' : '充电状态'
  console.log(`🔄 [${chartName}图表] 已还原至初始状态`)
  ElMessage.success('图表已还原')
}

// 初始化所有图表
const initAllCharts = async () => {
  await initCurrentChart()
  await initTemperatureChart()
  await initVoltageChart()
  await initChargeStateChart()
  
  // 添加单击放大功能
  currentChart.value?.on('click', () => toggleChartExpand('current'))
  temperatureChart.value?.on('click', () => toggleChartExpand('temperature'))
  voltageChart.value?.on('click', () => toggleChartExpand('voltage'))
  chargeStateChart.value?.on('click', () => toggleChartExpand('chargeState'))
  
  // 监听全屏变化
  document.addEventListener('fullscreenchange', handleFullscreenChange)
  document.addEventListener('webkitfullscreenchange', handleFullscreenChange)
  document.addEventListener('mozfullscreenchange', handleFullscreenChange)
  document.addEventListener('MSFullscreenChange', handleFullscreenChange)
  
  // 添加响应式监听
  window.addEventListener('resize', resizeAllCharts)
}

// 分析文件
const analyzeFile = async () => {
  if (fileList.value.length === 0) {
    ElMessage.warning('请先选择要分析的文件')
    return
  }

  const file = fileList.value[0].raw
  if (!file) {
    ElMessage.error('文件读取失败')
    return
  }

  try {
    uploading.value = true
    analyzing.value = true
    uploadProgress.value = 10

    const formData = new FormData()
    formData.append('file', file)

    ElMessage.info('正在上传文件...')
    uploadProgress.value = 30

    const apiUrl = `${API_URL}/analyze`
    console.log('=== API 请求信息 ===')
    console.log('API_URL:', API_URL)
    console.log('完整API地址:', apiUrl)
    console.log('当前页面地址:', window.location.href)
    console.log('上传文件:', file.name, '大小:', file.size, 'bytes')
    console.log('===================')

    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 60000)

    try {
      const response = await fetch(apiUrl, {
        method: 'POST',
        body: formData,
        signal: controller.signal
      })

      clearTimeout(timeoutId)
      console.log('响应状态:', response.status, response.statusText)
      uploadProgress.value = 60
      
      if (!response.ok) {
        const errorText = await response.text()
        console.error('错误响应内容:', errorText)
        
        let errorData
        try {
          errorData = JSON.parse(errorText)
          throw new Error(errorData.error || errorData.details || `服务器错误 (${response.status})`)
        } catch (parseError) {
          throw new Error(`服务器错误 (${response.status}): ${errorText.substring(0, 200)}`)
        }
      }

      ElMessage.info('正在分析文件...')
      const data = await response.json()
      console.log('分析结果:', data)
      uploadProgress.value = 90

      // 保存分析结果和原始数据
      analysisResults.value = data.stats
      chartData.value = data.data

      uploadProgress.value = 100
      ElMessage.success('分析完成！')

      // 初始化图表
      await initAllCharts()

      // 3秒后重置进度条
      setTimeout(() => {
        uploadProgress.value = 0
      }, 3000)

    } catch (fetchError: any) {
      if (fetchError.name === 'AbortError') {
        throw new Error('请求超时，请检查后端服务器是否正常运行')
      }
      throw fetchError
    }

  } catch (error: any) {
    console.error('分析失败详情:', error)
    let errorMessage = '文件处理失败'
    
    if (error.message) {
      errorMessage += '：' + error.message
    }
    
    if (error.message && error.message.includes('fetch')) {
      errorMessage = '无法连接到后端服务器，请确认后端服务已启动'
    }
    
    ElMessage.error(errorMessage)
    uploadProgress.value = 0
  } finally {
    uploading.value = false
    analyzing.value = false
  }
}

// 下载图表
const downloadChart = () => {
  if (!currentChart.value || !temperatureChart.value || !voltageChart.value) {
    ElMessage.warning('请先上传并分析日志文件')
    return
  }

  const downloadSingleChart = (chart: any, name: string) => {
    const url = chart.getDataURL({
      type: 'png',
      pixelRatio: 2,
      backgroundColor: '#fff'
    })

    const link = document.createElement('a')
    link.href = url
    link.download = `${name}_${Date.now()}.png`
    link.click()
  }

  downloadSingleChart(currentChart.value, '电流分析')
  setTimeout(() => downloadSingleChart(temperatureChart.value, '温度分析'), 100)
  setTimeout(() => downloadSingleChart(voltageChart.value, '电压分析'), 200)
  
  ElMessage.success('图表已下载(3张)')
}

// 导出数据
const exportData = () => {
  if (!analysisResults.value) return

  const avgCurrentFormatted = formatCurrent(analysisResults.value.avg_current)
  const maxCurrentFormatted = formatCurrent(analysisResults.value.max_current)
  const minCurrentFormatted = formatCurrent(analysisResults.value.min_current)

  const data: any = {
    分析时间: new Date().toLocaleString('zh-CN'),
    总数据点: analysisResults.value.total_points,
    平均电流: `${avgCurrentFormatted.value} ${avgCurrentFormatted.unit}`,
    最大电流: `${maxCurrentFormatted.value} ${maxCurrentFormatted.unit}`,
    最小电流: `${minCurrentFormatted.value} ${minCurrentFormatted.unit}`,
    平均温度: analysisResults.value.avg_temp.toFixed(1) + ' °C',
  }

  // 添加充电状态统计信息
  if (analysisResults.value.charge_state_counts) {
    data.充电状态统计 = {
      停充: analysisResults.value.charge_state_counts.no_charge,
      放电: analysisResults.value.charge_state_counts.discharge,
      预充电: analysisResults.value.charge_state_counts.precharge,
      CC恒流充电: analysisResults.value.charge_state_counts.cc_charge,
      CV恒压充电: analysisResults.value.charge_state_counts.cv_charge,
      充满: analysisResults.value.charge_state_counts.full,
      充电完成: analysisResults.value.charge_state_counts.done,
      充电错误: analysisResults.value.charge_state_counts.fault
    }
  }

  const jsonStr = JSON.stringify(data, null, 2)
  const blob = new Blob([jsonStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `pm_stats_${Date.now()}.json`
  link.click()
  URL.revokeObjectURL(url)
  ElMessage.success('数据已导出')
}
</script>

<template>
  <div class="log-analyzer-plugin">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span class="title">📊 日志分析</span>
        </div>
      </template>

      <!-- 文件上传区域 -->
      <div class="upload-section">
        <el-upload
          v-model:file-list="fileList"
          class="upload-demo"
          drag
          :auto-upload="false"
          :limit="1"
          :before-upload="beforeUpload"
          :on-change="handleFileChange"
          :on-remove="handleRemove"
          accept=".log"
        >
          <el-icon class="el-icon--upload"><Upload /></el-icon>
          <div class="el-upload__text">
            将文件拖到此处，或<em>点击上传</em>
          </div>
          <template #tip>
            <div class="el-upload__tip">
              只支持 .log 格式文件，且不超过 30MB
            </div>
          </template>
        </el-upload>

        <!-- 分析按钮 -->
        <div class="action-buttons">
          <el-button
            type="primary"
            :icon="TrendCharts"
            :loading="analyzing"
            :disabled="fileList.length === 0"
            @click="analyzeFile"
            size="large"
          >
            {{ analyzing ? '分析中...' : '开始分析' }}
          </el-button>
        </div>

        <!-- 上传进度 -->
        <el-progress
          v-if="uploadProgress > 0"
          :percentage="uploadProgress"
          :status="uploadProgress === 100 ? 'success' : undefined"
          class="upload-progress"
        />
      </div>

      <!-- 分析结果 -->
      <el-divider v-if="analysisResults" />

      <div v-if="analysisResults" class="results-section">
        <div class="results-header">
          <h3>📈 分析结果</h3>
          <div class="header-actions">
            <el-button :icon="DocumentChecked" @click="exportData" size="small">
              导出数据
            </el-button>
            <el-button type="primary" @click="downloadChart" size="small">
              下载图表
            </el-button>
          </div>
        </div>
        
        <!-- 使用提示 - 可折叠 -->
        <el-collapse v-model="showUsageTips" style="margin-bottom: 20px;">
          <el-collapse-item name="usage">
            <template #title>
              <div style="display: flex; align-items: center; font-size: 14px; font-weight: 500;">
                <el-icon style="margin-right: 8px;"><InfoFilled /></el-icon>
                💡 图表交互提示
              </div>
            </template>
            <div style="font-size: 12px; line-height: 1.8; padding: 8px 16px; background: #f5f7fa; border-radius: 4px;">
              • <strong>还原按钮</strong>：一键还原X轴和Y轴到初始状态<br/>
              • <strong>全屏按钮</strong>：浏览器全屏查看图表 | <strong>单击图表</strong>：放大查看 | <strong>双击图表</strong>：退出放大<br/>
              • <strong>鼠标滚轮</strong>：缩放 X 轴(时间) | <strong>Ctrl+滚轮</strong>：缩放 Y 轴(数值) | <strong>鼠标拖拽</strong>：平移 X 轴<br/>
              • <strong>X 轴滑块</strong>：精确控制时间范围 | <strong>Y 轴滑块</strong>：精确控制数值范围
            </div>
          </el-collapse-item>
        </el-collapse>

        <!-- 统计卡片 - 可折叠 -->
        <el-collapse v-model="showStatsCards" style="margin-bottom: 20px;">
          <el-collapse-item name="stats">
            <template #title>
              <div style="display: flex; align-items: center; font-size: 14px; font-weight: 500;">
                <el-icon style="margin-right: 8px;"><DataAnalysis /></el-icon>
                📊 统计数据
              </div>
            </template>
            <el-row :gutter="20" class="stats-cards">
              <el-col :xs="12" :sm="8" :md="4">
                <el-card class="stat-card">
                  <div class="stat-label">总数据点</div>
                  <div class="stat-value">{{ analysisResults.total_points }}</div>
                </el-card>
              </el-col>
              <el-col :xs="12" :sm="8" :md="4">
                <el-card class="stat-card">
                  <div class="stat-label">平均电流</div>
                  <div class="stat-value">{{ formatCurrent(analysisResults.avg_current).value }}</div>
                  <div class="stat-unit">{{ formatCurrent(analysisResults.avg_current).unit }}</div>
                </el-card>
              </el-col>
              <el-col :xs="12" :sm="8" :md="4">
                <el-card class="stat-card">
                  <div class="stat-label">最大电流</div>
                  <div class="stat-value">{{ formatCurrent(analysisResults.max_current).value }}</div>
                  <div class="stat-unit">{{ formatCurrent(analysisResults.max_current).unit }}</div>
                </el-card>
              </el-col>
              <el-col :xs="12" :sm="8" :md="4">
                <el-card class="stat-card">
                  <div class="stat-label">最小电流</div>
                  <div class="stat-value">{{ formatCurrent(analysisResults.min_current).value }}</div>
                  <div class="stat-unit">{{ formatCurrent(analysisResults.min_current).unit }}</div>
                </el-card>
              </el-col>
              <el-col :xs="12" :sm="8" :md="4">
                <el-card class="stat-card">
                  <div class="stat-label">平均温度</div>
                  <div class="stat-value">{{ analysisResults.avg_temp.toFixed(1) }}</div>
                  <div class="stat-unit">°C</div>
                </el-card>
              </el-col>
            </el-row>
          </el-collapse-item>
        </el-collapse>

        <!-- 充电状态统计 -->
        <el-row :gutter="16" v-if="analysisResults.charge_state_counts" style="margin-top: 16px;">
          <el-col :span="24">
            <el-card class="stats-card">
              <template #header>
                <div class="card-header">
                  <span class="title">⚡ 充电状态统计</span>
                </div>
              </template>
              <el-row :gutter="12">
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(0) }"></span>
                      停充
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.no_charge }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(1) }"></span>
                      放电
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.discharge }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(2) }"></span>
                      预充电
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.precharge }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(3) }"></span>
                      CC恒流
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.cc_charge }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(4) }"></span>
                      CV恒压
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.cv_charge }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(5) }"></span>
                      充满
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.full }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(6) }"></span>
                      完成
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.done }}</div>
                  </div>
                </el-col>
                <el-col :xs="12" :sm="8" :md="3">
                  <div class="charge-state-item">
                    <div class="state-label">
                      <span class="state-dot" :style="{ backgroundColor: getChargeStateColor(7) }"></span>
                      错误
                    </div>
                    <div class="state-value">{{ analysisResults.charge_state_counts.fault }}</div>
                  </div>
                </el-col>
              </el-row>
            </el-card>
          </el-col>
        </el-row>

        <!-- 图表展示 -->
        <!-- 图表展示 - 2x2 网格布局 -->
        <div class="charts-wrapper">
          <!-- 第一行：电流和温度 -->
          <div class="chart-row">
            <!-- 电流图表 -->
            <div class="chart-card">
              <div class="chart-header">
                <span class="chart-title">⚡ 电流变化趋势</span>
                <div class="chart-actions">
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="toggleFullscreen('current')"
                    :icon="fullscreenChartType === 'current' ? 'CloseBold' : 'FullScreen'"
                  >
                    {{ fullscreenChartType === 'current' ? '退出全屏' : '全屏' }}
                  </el-button>
                </div>
              </div>
              <div class="chart-container-wrapper">
                <div 
                  id="currentChart" 
                  class="echarts-container"
                  :class="{ 'expanded': expandedChart === 'current', 'collapsed': expandedChart && expandedChart !== 'current' }"
                  @dblclick="expandedChart = null"
                ></div>
                <!-- 还原按钮 -->
                <el-button 
                  class="reset-button"
                  size="small" 
                  @click="resetChart('current')"
                  title="还原显示范围"
                >
                  还原
                </el-button>
              </div>
            </div>
            
            <!-- 温度图表 -->
            <div class="chart-card">
              <div class="chart-header">
                <span class="chart-title">🌡️ 温度变化趋势</span>
                <div class="chart-actions">
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="toggleFullscreen('temperature')"
                    :icon="fullscreenChartType === 'temperature' ? 'CloseBold' : 'FullScreen'"
                  >
                    {{ fullscreenChartType === 'temperature' ? '退出全屏' : '全屏' }}
                  </el-button>
                </div>
              </div>
              <div class="chart-container-wrapper">
                <div 
                  id="temperatureChart" 
                  class="echarts-container"
                  :class="{ 'expanded': expandedChart === 'temperature', 'collapsed': expandedChart && expandedChart !== 'temperature' }"
                  @dblclick="expandedChart = null"
                ></div>
                <!-- 还原按钮 -->
                <el-button 
                  class="reset-button"
                  size="small" 
                  @click="resetChart('temperature')"
                  title="还原显示范围"
                >
                  还原
                </el-button>
              </div>
            </div>
          </div>
          
          <!-- 第二行：电压和充电状态 -->
          <div class="chart-row">
            <!-- 电压图表 -->
            <div class="chart-card">
              <div class="chart-header">
                <span class="chart-title">🔋 电压变化趋势</span>
                <div class="chart-actions">
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="toggleFullscreen('voltage')"
                    :icon="fullscreenChartType === 'voltage' ? 'CloseBold' : 'FullScreen'"
                  >
                    {{ fullscreenChartType === 'voltage' ? '退出全屏' : '全屏' }}
                  </el-button>
                </div>
              </div>
              <div class="chart-container-wrapper">
                <div 
                  id="voltageChart" 
                  class="echarts-container"
                  :class="{ 'expanded': expandedChart === 'voltage', 'collapsed': expandedChart && expandedChart !== 'voltage' }"
                  @dblclick="expandedChart = null"
                ></div>
                <!-- 还原按钮 -->
                <el-button 
                  class="reset-button"
                  size="small" 
                  @click="resetChart('voltage')"
                  title="还原显示范围"
                >
                  还原
                </el-button>
              </div>
            </div>

            <!-- 充电状态图表 -->
            <div class="chart-card">
              <div class="chart-header">
                <span class="chart-title">⚡ 充电状态变化</span>
                <div class="chart-actions">
                  <el-button 
                    type="primary" 
                    size="small" 
                    @click="toggleFullscreen('chargeState')"
                  :icon="fullscreenChartType === 'chargeState' ? 'CloseBold' : 'FullScreen'"
                >
                  {{ fullscreenChartType === 'chargeState' ? '退出全屏' : '全屏' }}
                </el-button>
              </div>
            </div>
            <div class="chart-container-wrapper">
              <div 
                id="chargeStateChart" 
                class="echarts-container"
                :class="{ 'expanded': expandedChart === 'chargeState', 'collapsed': expandedChart && expandedChart !== 'chargeState' }"
                @dblclick="expandedChart = null"
              ></div>
              <!-- 还原按钮 -->
              <el-button 
                class="reset-button"
                size="small" 
                @click="resetChart('chargeState')"
                title="还原显示范围"
              >
                还原
              </el-button>
            </div>
          </div>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <el-empty
        v-else
        description="上传日志文件开始分析"
        :image-size="150"
      />
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.log-analyzer-plugin {
  max-width: 1600px;
  margin: 0 auto;
  padding: 20px;

  @media (max-width: 1650px) {
    max-width: 1400px;
  }

  @media (max-width: 1450px) {
    max-width: 1200px;
  }

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;

    .title {
      font-size: 20px;
      font-weight: 600;
      color: #303133;
    }
  }

  .upload-section {
    .upload-demo {
      margin-bottom: 20px;

      :deep(.el-upload-dragger) {
        padding: 40px;
        border: 2px dashed #d9d9d9;
        border-radius: 8px;
        transition: all 0.3s;

        &:hover {
          border-color: #409eff;
          background: rgba(64, 158, 255, 0.05);
        }
      }

      :deep(.el-icon--upload) {
        font-size: 67px;
        color: #409eff;
        margin-bottom: 16px;
      }

      :deep(.el-upload__text) {
        color: #606266;
        font-size: 14px;

        em {
          color: #409eff;
          font-style: normal;
        }
      }

      :deep(.el-upload__tip) {
        color: #909399;
        font-size: 12px;
        margin-top: 10px;
      }
    }

    .action-buttons {
      display: flex;
      justify-content: center;
      margin: 20px 0;
    }

    .upload-progress {
      margin-top: 15px;
    }
  }

  .results-section {
    .results-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;

      h3 {
        margin: 0;
        font-size: 18px;
        font-weight: 600;
        color: #303133;
      }

      .header-actions {
        display: flex;
        gap: 10px;
      }
    }

    .stats-cards {
      margin-bottom: 30px;

      .stat-card {
        text-align: center;
        border-radius: 8px;
        transition: all 0.3s;
        cursor: default;

        &:hover {
          transform: translateY(-5px);
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        }

        .stat-label {
          font-size: 14px;
          color: #909399;
          margin-bottom: 8px;
        }

        .stat-value {
          font-size: 28px;
          font-weight: bold;
          color: #409eff;
          line-height: 1;
        }

        .stat-unit {
          font-size: 14px;
          color: #606266;
          margin-top: 4px;
        }
      }
    }

    .charge-state-item {
      text-align: center;
      padding: 12px 8px;
      border-radius: 6px;
      background: #f5f7fa;
      transition: all 0.3s;

      &:hover {
        background: #e8eaf0;
        transform: translateY(-2px);
      }

      .state-label {
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 13px;
        color: #606266;
        margin-bottom: 8px;
        gap: 6px;

        .state-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
          display: inline-block;
        }
      }

      .state-value {
        font-size: 24px;
        font-weight: bold;
        color: #303133;
      }
    }

    .charts-wrapper {
      display: flex;
      flex-direction: column;
      gap: 20px;
      position: relative;

      .chart-row {
        display: flex;
        gap: 20px;
        width: 100%;

        @media (max-width: 1200px) {
          flex-direction: column;
        }
      }

      .chart-card {
        flex: 1;
        min-width: 0;
        background: #fff;
        border-radius: 8px;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
        overflow: hidden;
        transition: all 0.3s ease;

        &:hover {
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
          transform: translateY(-2px);
        }

        .chart-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
          padding: 12px 20px;
          background: linear-gradient(135deg, #f5f7fa 0%, #e8eef5 100%);
          border-bottom: 1px solid #e4e7ed;

          .chart-title {
            font-size: 16px;
            font-weight: 600;
            color: #303133;
            display: flex;
            align-items: center;
            gap: 8px;
          }

          .chart-actions {
            display: flex;
            gap: 8px;
            align-items: center;
          }
        }

        .chart-container-wrapper {
          position: relative;
        }

        .reset-button {
          position: absolute;
          right: 20px;
          bottom: 20px;
          z-index: 10;
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(5px);
          border: 1px solid #dcdfe6;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
          transition: all 0.3s;

          &:hover {
            background: #409eff;
            color: #fff;
            border-color: #409eff;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(64, 158, 255, 0.4);
          }
        }
      }

      .chart-divider {
        margin: 30px 0;
        
        .el-icon {
          color: #409eff;
          font-size: 16px;
        }
      }

      .echarts-container {
        width: 100%;
        height: 400px;
        min-height: 350px;
        padding: 10px;
        cursor: grab;
        transition: all 0.3s ease;
        
        @media (max-width: 1200px) {
          height: 450px;
        }
        
        &:active {
          cursor: grabbing;
        }
        
        &.expanded {
          position: fixed;
          top: 5%;
          left: 5%;
          width: 90%;
          height: 85%;
          z-index: 1000;
          max-height: 85vh;
          cursor: grab;
          border-radius: 8px;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
          animation: expandChart 0.3s ease;
        }
        
        &.collapsed {
          opacity: 0.3;
          pointer-events: none;
        }
        
        // 全屏样式
        &:fullscreen {
          width: 100%;
          height: 100%;
          max-height: 100vh;
          padding: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #fff;
        }
        
        &:-webkit-full-screen {
          width: 100%;
          height: 100%;
          max-height: 100vh;
          padding: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #fff;
        }
        
        &:-moz-full-screen {
          width: 100%;
          height: 100%;
          max-height: 100vh;
          padding: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #fff;
        }
        
        &:-ms-fullscreen {
          width: 100%;
          height: 100%;
          max-height: 100vh;
          padding: 20px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #fff;
        }
      }
    }
  }
}

@keyframes expandChart {
  from {
    transform: scale(0.9);
    opacity: 0.8;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}

// 响应式设计
@media (max-width: 768px) {
  .log-analyzer-plugin {
    padding: 10px;

    .results-section {
      .results-header {
        flex-direction: column;
        gap: 15px;
        align-items: flex-start;

        .header-actions {
          width: 100%;
          justify-content: space-between;
        }
      }

      .stats-cards {
        .stat-card .stat-value {
          font-size: 22px;
        }
      }
    }
  }
}

// 动画效果
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.results-section {
  animation: fadeIn 0.5s ease-out;
}
</style>
