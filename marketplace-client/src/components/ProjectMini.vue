<template>
  <v-card color="blue-grey darken-2" class="white--text" :to="projectPath" hover>
    <v-toolbar color="orange" dense>
      <v-toolbar-title>{{ project.title }}</v-toolbar-title>
    </v-toolbar>
    <v-card-text>
      <div style="height:150px; overflow: hidden;">{{ project.description }}</div>
    </v-card-text>
    <v-toolbar color="transparent" flat>
        <v-chip md6 v-for="tag in project.tags" :key="tag">{{tag}}</v-chip>
    </v-toolbar>
  </v-card>
</template>

<script>
export default {
  props: ['project'],
  name: 'project-mini',
  computed: {
    projectPath () {
      return '/project/' + this.project.id
    }
  }
}
</script>
