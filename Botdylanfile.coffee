module.exports =
  username: process.env.USERNAME or 'botdylan'
  password: process.env.PASSWORD or 'blood-on-the-tracks'
  auth: process.env.AUTH or 'basic'
  url: process.env.URL or 'https://goodeggs-fairy.herokuapp.com'
  port: process.env.PORT or 5000
  repositories:
   "goodeggs/garbanzo":
     hooks:
       'push': ['data-model-changes']

   "goodeggs/kale":
     hooks:
       'push': ['data-model-changes']

   "goodeggs/orzo":
     hooks:
       'push': ['data-model-changes']

