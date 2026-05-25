import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'home',
    component: () => import('./pages/Home.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('./pages/Login.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('./pages/Dashboard.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/learning/:pathId',
    name: 'learning-path',
    component: () => import('./pages/LearningPath.vue'),
    meta: { requiresAuth: true, offline: true },
  },
  {
    path: '/content/:uuid',
    name: 'content',
    component: () => import('./pages/ContentPlayer.vue'),
    meta: { requiresAuth: true, offline: true },
  },
  {
    path: '/sync',
    name: 'sync',
    component: () => import('./pages/SyncCenter.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/offline',
    name: 'offline',
    component: () => import('./pages/OfflineMode.vue'),
    meta: { requiresAuth: false },
  },
  {
    path: '/profile',
    name: 'profile',
    component: () => import('./pages/Profile.vue'),
    meta: { requiresAuth: true },
  },
]

export const router = createRouter({
  history: createWebHistory(),
  routes,
})
