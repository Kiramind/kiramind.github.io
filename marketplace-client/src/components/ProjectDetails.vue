<template>
  <div>
    <main-jumbotron title="LINE Marketplace" subtitle="Collaborate with other to reach greatness!"></main-jumbotron>
    <v-layout>
      <v-flex mt-3 sm12 offset-md2 md8>
        <v-toolbar color="orange" dark>
          <v-toolbar-title>{{project.title}}</v-toolbar-title>
        </v-toolbar>
        <v-card>
          <v-card-title v-if="project.targetDate">
            <span class="grey--text">Target date: {{project.targetDate}}</span>
          </v-card-title>
          <v-card-title>
            <p v-html="compiledMarkdown"></p>
          </v-card-title>
          <div class="mx-2 mb">
            <v-chip v-for="tag in allProjectTags" :key="tag">{{tag}}</v-chip>
          </div>
        </v-card>
      </v-flex>
    </v-layout>
  </div>
</template>

<script>
import MainJumbotron from './MainJumbotron.vue'
import Marked from 'marked'
import Methods from './FakeEntityMethods.js'

export default {
  components: {
    MainJumbotron
  },
  created () {
    let projectId = this.$route.params.id
    Promise.all([
      this.getProject(projectId)
    ]).then((values) => {
      this.project = values[0]
    })
  },
  data () {
    return {
      project: {}
    }
  },
  computed: {
    compiledMarkdown () {
      if (this.project.description) {
        return Marked(this.project.description, { sanitize: true })
      }
      return ''
    },
    allProjectTags () {
      return this.project.languageTags.concat(this.project.topicTags)
    }
  },
  methods: Object.assign(Methods, {
    preview (project) {
      console.log('TODO display preview', project)
    }
  }),
  name: 'Project_Edition'
}
</script>
