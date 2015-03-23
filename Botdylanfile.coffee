module.exports =
  username: process.env.USERNAME or 'botdylan'
  password: process.env.PASSWORD or 'blood-on-the-tracks'
  auth: process.env.AUTH or 'basic'
  url: process.env.URL or 'https://goodeggs-fairy.herokuapp.com'
  port: process.env.PORT or 5000
  repositories:
   "goodeggs/garbanzo":
     crons:
       "0 0 */1 * * *": ['goodeggs-dependencies']
     hooks:
       'push': ['data-model-changes']
   "goodeggs/kale":
     crons:
       "0 0 */1 * * *": ['goodeggs-dependencies']
   "goodeggs/lentil":
     crons:
       "0 0 */1 * * *": ['goodeggs-dependencies']
   "goodeggs/admin":
     crons:
       "0 0 */1 * * *": ['goodeggs-dependencies']
   "goodeggs/manage":
     crons:
       "0 0 */1 * * *": ['goodeggs-dependencies']

