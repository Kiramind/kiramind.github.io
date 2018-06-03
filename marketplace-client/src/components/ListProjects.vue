<template>
  <div>
    <main-jumbotron title="LINE Project Marketplace" subtitle="Help your colleagues project and learn while doing it !"></main-jumbotron>
    <v-layout row>
      <v-flex offset-md3 md2>
        <v-select
          v-model="languageSelection"
          label="Filter Languages"
          multiple
          :items="languageItems"
        ></v-select>
      </v-flex>
      <v-flex offset-md2 md2>
        <v-select
          v-model="topicSelection"
          label="Filter Topics"
          multiple
          :items="topicItems"
        ></v-select>
      </v-flex>
    </v-layout>
    <v-layout row>
      <v-container fluid grid-list-xl>
        <v-layout row wrap>
          <v-flex xs4 md3 lg-offset-2 lg2 v-for="project in projects" :key="project.id">
            <project-mini :project="project"></project-mini>
          </v-flex>
        </v-layout>
    </v-container>
    </v-layout>
    <div class="text-xs-center">
      <v-pagination :length="paging.numberOfPages" v-model="paging.page" @input="goToPage" circle></v-pagination>
    </div>
  </div>
</template>

<script>
import Methods from './FakeEntityMethods.js'
import ProjectMini from './ProjectMini.vue'
import MainJumbotron from './MainJumbotron.vue'

export default {
  components: {
    ProjectMini,
    MainJumbotron
  },
  created () {
    Promise.all([
      this.getLanguages(),
      this.getTopics(),
      this.getProjects(this.paging)
    ]).then((values) => {
      this.languageItems = values[0]
      this.topicItems = values[1]

      let projectResult = values[2]
      this.projects = projectResult.projects
      this.paging.numberOfPages = projectResult.numberOfPages
    })
  },
  data () {
    return {
      languageSelection: [],
      languageItems: [],
      topicSelection: [],
      topicItems: [],
      projects: [],
      paging: {
        page: 1,
        numberPerPage: 10,
        numberOfPages: 1
      },
      gradient: 'to top right, rgba(0,0,0, .7), rgba(40,40,40, .7)'
    }
  },
  methods: Object.assign(Methods, {
    goToPage (page) {
      // this.projects.splice(0, this.projects.length)
      this.getProjects(this.paging).then((res) => {
        this.projects = res.projects
      })
    }
  }),
  name: 'App'
}
</script>
