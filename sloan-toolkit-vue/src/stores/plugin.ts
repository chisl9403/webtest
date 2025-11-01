import { defineStore } from 'pinia'

export const usePluginStore = defineStore('plugin', {
  state: () => ({
    plugins: new Map(),
    configs: {}
  }),
  
  actions: {
    register(plugin: any) {
      this.plugins.set(plugin.meta.id, plugin)
      console.log(`✅ 插件 [${plugin.meta.name}] 已注册`)
    }
  }
})
