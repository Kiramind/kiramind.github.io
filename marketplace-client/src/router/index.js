import Vue from 'vue'
import Router from 'vue-router'
import ListProjects from '@/components/ListProjects'
import EditProject from '@/components/EditProject'
import ProjectDetails from '@/components/ProjectDetails'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'ListProjects',
      component: ListProjects
    },
    {
      path: '/project/edition/',
      name: 'CreateProject',
      component: EditProject
    },
    {
      path: '/project/edition/:id',
      name: 'EditProject',
      component: EditProject
    },
    {
      path: '/project/:id',
      name: 'ProjectDetails',
      component: ProjectDetails
    }
  ]
})
