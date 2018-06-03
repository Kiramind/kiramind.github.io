import Faker from 'faker'
const LANGUAGES = ['Javascript', 'Java', 'C#', 'Go', 'Python', 'Perl']
const TOPICS = ['IoT', 'Blockchain', 'Server', 'Android', 'iOS', 'Web']
const Methods = {
  getLanguages () {
    return Promise.resolve(LANGUAGES)
  },
  getTopics () {
    return Promise.resolve(TOPICS)
  },
  getProjects (paging) {
    let projects = []
    for (var i = 0; i < paging.numberPerPage; i++) {
      projects.push(this.createFakeProject(i))
    }
    return Promise.resolve({
      projects: projects,
      numberOfPages: 6
    })
  },
  saveProject (project) {
    console.log('TODO save project: ', project.targetDate)
  },
  getProject (id) {
    return Promise.resolve(this.createFakeProject(id))
  },
  createFakeProject (id) {
    return {
      id: id,
      title: Faker.company.companyName(),
      // description: Faker.lorem.paragraph(30),
      description: this.createDescription(),
      languageTags: [this.randomLanguageTags()],
      topicTags: [this.randomTopicTags()],
      targetDate: '2018-05-07'
    }
  },
  newProject () {
    return {
      id: null,
      languageTags: [],
      topicTags: [],
      targetDate: null
    }
  },
  randomTopicTags () {
    return TOPICS[Faker.random.number(TOPICS.length)]
  },
  randomLanguageTags () {
    return LANGUAGES[Faker.random.number(LANGUAGES.length)]
  },
  formatDate (date) {
    if (!date) return null

    const [year, month, day] = date.split('-')
    return `${month}/${day}/${year}`
  },
  createDescription () {
    let values = [
      '# ', Faker.lorem.sentence(), '\n',
      '## ', Faker.lorem.sentence(), '\n',
      Faker.lorem.paragraph(10), '\n',
      '### ', Faker.lorem.sentence(), '\n',
      Faker.lorem.paragraph(10), '\n'
    ]

    return values.join('')
  }
}

export default Methods
