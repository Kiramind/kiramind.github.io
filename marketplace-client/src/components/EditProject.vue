<template>
  <div>
    <main-jumbotron title="Add your project to the Marketplace" subtitle="Find people to join your team!"></main-jumbotron>
    <v-layout>
      <v-flex mt-3 sm12 offset-md2 md8>
        <v-toolbar color="orange" dark>
          <v-toolbar-title>{{project.title}}</v-toolbar-title>
        </v-toolbar>
        <v-card>
          <v-container fluid grid-list-md>
            <v-form v-model="formValidity">
              <v-layout row>
              <v-flex sm12 md6>
                <v-text-field
                  v-model="project.title"
                  :rules="rules.name"
                  :counter="50"
                  label="Name"
                  required
                ></v-text-field>
              </v-flex>
              <v-flex sm12 offset-md2 md4>
                <v-menu
                  :close-on-content-click="true"
                  v-model="menu"
                  :nudge-right="40"
                  lazy
                  transition="scale-transition"
                  offset-y
                  full-width
                  max-width="290px"
                  min-width="290px"
                >
                  <v-text-field
                    slot="activator"
                    v-model="computedDateFormatted"
                    label="Target date for completion of the project"
                    hint="MM/DD/YYYY format"
                    persistent-hint
                    prepend-icon="event"
                    readonly
                  ></v-text-field>
                  <v-date-picker v-model="project.targetDate" no-title @input="menu = false"></v-date-picker>
                </v-menu>
              </v-flex>
            </v-layout>
              <v-layout row>
                <v-flex md12>
                  <v-text-field
                    name="Description"
                    label="Description"
                    v-model="project.description"
                    :rules="rules.description"
                    :counter="1000"
                    required
                    rows="10"
                    multi-line
                  ></v-text-field>
                </v-flex>
              </v-layout>
              <v-layout row>
                <v-flex sm12 md5>
                  <v-select
                    v-model="project.languageTags"
                    label="Languages"
                    multiple
                    :items="languageItems"
                    chips
                  ></v-select>
                </v-flex>
                <v-flex sm12 offset-md2 md5>
                  <v-select
                    v-model="project.topicTags"
                    label="Topics"
                    multiple
                    :items="topicItems"
                    chips
                  ></v-select>
                </v-flex>
              </v-layout>
              <v-toolbar color="transparent" flat>
                <v-spacer></v-spacer>
                <v-btn :disabled="!formValidity" @click="preview(project)" color="grey">Preview</v-btn>
                <v-btn :disabled="!formValidity" @click="saveProject(project)" color="orange">Create</v-btn>
              </v-toolbar>
            </v-form>
          </v-container>
        </v-card>
      </v-flex>
    </v-layout>
  </div>
</template>

<script>
import Methods from './FakeEntityMethods.js'
import MainJumbotron from './MainJumbotron.vue'

export default {
  components: {
    MainJumbotron
  },
  created () {
    let apis = [
      this.getLanguages(),
      this.getTopics()
    ]

    let projectId = this.$route.params.id
    if (projectId) {
      apis.push(this.getProject(projectId))
    }

    Promise.all(apis).then((values) => {
      this.languageItems = values[0]
      this.topicItems = values[1]
      if (projectId) {
        this.project = values[2]
      }
    })
  },
  data () {
    return {
      languageItems: [],
      topicItems: [],
      project: this.newProject(),
      gradient: 'to top right, rgba(0,0,0, .7), rgba(40,40,40, .7)',
      formValidity: false,
      menu: true,
      rules: {
        name: [
          v => !!v || 'Name is required',
          v => (!!v && v.length <= 50) || 'Name must be less than 50 characters',
          v => (!!v && v.length > 2) || 'Name must be more than 2 characters'
        ],
        description: [
          v => !!v || 'Description is required',
          v => (!!v && v.length <= 1500) || 'Description must be less than 1500 characters',
          v => (!!v && v.length > 10) || 'Description must be more than 10 characters'
        ]
      }
    }
  },
  computed: {
    computedDateFormatted () {
      return this.formatDate(this.project.targetDate)
    }
  },
  methods: Object.assign(Methods, {
    parseDate (date) {
      if (!date) return null

      const [month, day, year] = date.split('/')
      return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
    },
    preview (project) {
      console.log('TODO display preview', project)
    }
  }),
  name: 'Project_Edition'
}
</script>
