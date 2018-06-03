# marketplace-client

Web client for line marketplace

## Expected API
- `GET` https://example.com/languages/ - get language list
- `GET` https://example.com/topics/ - get topic list
- `GET` https://example.com/projects/?page=1&numberPerPage=10 - get project list
  - response: 
  ```
  {
    projects: [<project>, ...],
    numberOfPages: 6
  }
  ```
- `GET` https://example.com/projects/:id - get project
- `PUT` https://example.com/projects/:id - update project
- `POST` https://example.com/projects/ - create project

## Model
### Project
```json
{
  "id": 42,
  "title": "Shiny project",
  "description": "Once upon a time this project...",
  "languageTags": ["Java", "Vue"],
  "topicTags": ["Blockchain"],
  "targetDate": null
}
```


## Build Setup

``` bash
# install dependencies
npm install

# serve with hot reload at localhost:8080
npm run dev

# build for production with minification
npm run build

# build for production and view the bundle analyzer report
npm run build --report
```
