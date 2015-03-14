module.exports =
  username: process.env.USERNAME or "botdylan"
  password: process.env.PASSWORD or "blood-on-the-tracks"
  auth: process.env.AUTH or "basic"
  url: process.env.URL or "http://example.com"
  port: process.env.PORT or 5000
  repositories:
   "botdylan/test":
     crons:
       "0 0 0 * * *": ["ping"]
     hooks:
       issue_comment: ["pong"]
       push: ["cowboys"]

