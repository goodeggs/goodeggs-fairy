request = require 'request'
yaml = require 'js-yaml'
_ = require 'lodash'

class Folks
  @getInstance: (cb) ->
    request.get 'https://raw.githubusercontent.com/goodeggs/key-pository/master/folks.yml', (err, res, body) ->
      return cb(err) if err?
      return cb(new Error("unexpected status code #{res.statusCode} while fetching folks.yml")) unless res.statusCode is 200
      try
        folks = yaml.safeLoad body
        cb null, new Folks(folks)
      catch e
        cb(e)

  constructor: (@_folks) ->
    # NOOP
  
  recipient: (username) ->
    username = username.toLowerCase()
    person = _.find @_folks, ({github}) -> github.toLowerCase() is username
    person? and "#{person.name} <#{person.username}@goodeggs.com>"

module.exports = Folks

