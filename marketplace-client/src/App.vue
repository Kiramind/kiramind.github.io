<template>
  <v-app dark>
    <v-content>
      <router-view/>
    </v-content>
    </v-navigation-drawer>
    <v-footer app>
      <span>&copy; 2018</span>
    </v-footer>
  </v-app>
</template>

<script>
export default {
  data () {
    return {
    }
  },
  name: 'App'
}
</script>
