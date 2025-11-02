"""
RSS代理插件
提供RSS源的跨域代理访问
"""

from flask import Blueprint, jsonify, request
import feedparser
import requests
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

# 创建蓝图
rss_proxy_bp = Blueprint('rss_proxy', __name__)

@rss_proxy_bp.route('/36kr/rss', methods=['GET'])
def get_36kr_rss():
    """
    获取36氪RSS数据
    
    Returns:
        JSON: 格式化的RSS数据
    """
    try:
        # 36氪RSS源地址
        rss_url = 'https://36kr.com/feed'
        
        logger.info(f"开始获取36氪RSS: {rss_url}")
        
        # 设置请求头，模拟浏览器访问
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        }
        
        # 获取RSS内容
        response = requests.get(rss_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # 解析RSS
        feed = feedparser.parse(response.content)
        
        if not feed.entries:
            logger.warning("RSS解析结果为空")
            return jsonify({
                'success': False,
                'message': 'RSS解析结果为空',
                'items': []
            }), 200
        
        # 格式化数据
        items = []
        for entry in feed.entries:
            # 解析发布时间
            publish_time = None
            if hasattr(entry, 'published_parsed') and entry.published_parsed:
                publish_time = datetime(*entry.published_parsed[:6]).timestamp() * 1000
            elif hasattr(entry, 'updated_parsed') and entry.updated_parsed:
                publish_time = datetime(*entry.updated_parsed[:6]).timestamp() * 1000
            else:
                publish_time = datetime.now().timestamp() * 1000
            
            # 提取摘要（移除HTML标签）
            summary = ''
            if hasattr(entry, 'summary'):
                import re
                summary = re.sub(r'<[^>]+>', '', entry.summary)
                summary = summary.strip()[:200]  # 限制长度
            
            item = {
                'id': entry.get('id', entry.get('link', '')),
                'title': entry.get('title', ''),
                'summary': summary,
                'description': summary,
                'link': entry.get('link', ''),
                'publishTime': publish_time,
                'author': entry.get('author', ''),
            }
            items.append(item)
        
        logger.info(f"成功获取{len(items)}条RSS数据")
        
        return jsonify({
            'success': True,
            'count': len(items),
            'items': items,
            'feedTitle': feed.feed.get('title', '36氪'),
            'feedLink': feed.feed.get('link', 'https://36kr.com')
        })
        
    except requests.Timeout:
        logger.error("请求36氪RSS超时")
        return jsonify({
            'success': False,
            'message': '请求超时',
            'items': []
        }), 504
        
    except requests.RequestException as e:
        logger.error(f"请求36氪RSS失败: {str(e)}")
        return jsonify({
            'success': False,
            'message': f'请求失败: {str(e)}',
            'items': []
        }), 502
        
    except Exception as e:
        logger.error(f"解析RSS失败: {str(e)}", exc_info=True)
        return jsonify({
            'success': False,
            'message': f'解析失败: {str(e)}',
            'items': []
        }), 500


@rss_proxy_bp.route('/rss/proxy', methods=['GET'])
def proxy_rss():
    """
    通用RSS代理接口
    
    Query Parameters:
        url (str): RSS源URL
        
    Returns:
        JSON: 格式化的RSS数据
    """
    try:
        rss_url = request.args.get('url')
        
        if not rss_url:
            return jsonify({
                'success': False,
                'message': '缺少url参数',
                'items': []
            }), 400
        
        logger.info(f"代理RSS请求: {rss_url}")
        
        # 设置请求头
        headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Accept': 'application/rss+xml, application/xml, text/xml, */*',
        }
        
        # 获取RSS内容
        response = requests.get(rss_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        # 解析RSS
        feed = feedparser.parse(response.content)
        
        if not feed.entries:
            return jsonify({
                'success': False,
                'message': 'RSS解析结果为空',
                'items': []
            }), 200
        
        # 格式化数据
        items = []
        for entry in feed.entries:
            publish_time = None
            if hasattr(entry, 'published_parsed') and entry.published_parsed:
                publish_time = datetime(*entry.published_parsed[:6]).timestamp() * 1000
            elif hasattr(entry, 'updated_parsed') and entry.updated_parsed:
                publish_time = datetime(*entry.updated_parsed[:6]).timestamp() * 1000
            
            # 提取摘要
            summary = ''
            if hasattr(entry, 'summary'):
                import re
                summary = re.sub(r'<[^>]+>', '', entry.summary).strip()[:200]
            
            item = {
                'id': entry.get('id', entry.get('link', '')),
                'title': entry.get('title', ''),
                'summary': summary,
                'link': entry.get('link', ''),
                'publishTime': publish_time,
            }
            items.append(item)
        
        return jsonify({
            'success': True,
            'count': len(items),
            'items': items,
            'feedTitle': feed.feed.get('title', ''),
            'feedLink': feed.feed.get('link', '')
        })
        
    except Exception as e:
        logger.error(f"RSS代理失败: {str(e)}", exc_info=True)
        return jsonify({
            'success': False,
            'message': f'代理失败: {str(e)}',
            'items': []
        }), 500
