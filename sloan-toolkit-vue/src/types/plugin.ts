import type { Component } from 'vue'
import type { RouteRecordRaw } from 'vue-router'

export interface PluginMeta {
  id: string
  name: string
  version: string
  author: string
  description: string
  icon: string
  homepage?: string
}

export interface PluginConfig {
  enabled: boolean
  autoLoad?: boolean
  [key: string]: any
}

export interface Plugin {
  meta: PluginMeta
  config: PluginConfig
  component: Component
  install?: (app: any) => void | Promise<void>
  routes?: RouteRecordRaw[]
}
