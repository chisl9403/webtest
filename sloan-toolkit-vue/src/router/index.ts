import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'Home',
      component: () => import('@/views/Home.vue')
    },
    {
      path: '/config',
      name: 'PluginConfig',
      component: () => import('@/views/PluginConfig.vue')
    }
  ]
})

export default router
