<template>
  <div>
    <v-jumbotron pt-5 row wrap src="/static/top-banner.jpg" :gradient="gradient" height="230px">
      <v-toolbar color="transparent" flat>
        <v-spacer></v-spacer>
        <v-toolbar-items>
          <v-btn to="/project/edition/" flat>Add Project</v-btn>
          <v-btn flat>LINE Login</v-btn>
        </v-toolbar-items>
      </v-toolbar>
      <v-flex mb-5>
        <router-link to="/" tag="h3" class="display-2 text-md-center" style="cursor: pointer">{{title}}</router-link>
        <div class="title mt-5 text-md-center">{{subtitle}}</div>
      </v-flex>
    </v-jumbotron>
    <v-divider></v-divider>
  </div>
</template>

<script>
export default {
  props: ['title', 'subtitle'],
  data () {
    return {
      gradient: 'to top right, rgba(0,0,0, .7), rgba(40,40,40, .7)'
    }
  },
  name: 'main-jumbotron'
}
</script>
