fibrous = require 'fibrous'
request = require 'request'
semver = require 'semver'

class GithubFileGateway
  constructor: (@raw) ->
    # noop

  content: (encoding='utf8') ->
    new Buffer(@raw.content, @raw.encoding).toString(encoding)

class GithubRepoService

  constructor: (@_client, {@user, @repo}) ->

  getFile: fibrous (path) ->
    raw = @_client.repos.sync.getContent {@user, @repo, path}
    new GithubFileGateway raw

module.exports = (bot, repo) ->
  {github} = bot
  repoService = new GithubRepoService github, user: repo.owner, repo: repo.name
  trace = (str) ->
    bot.trace "goodeggs-dependencies #{repo.owner}/#{repo.name}: #{str}"

  fibrous.run ->
    trace 'starting'

    for moduleName in ['goodeggs-logger', 'goodeggs-stats']

      trace "checking module #{moduleName}"

      auth = new Buffer(process.env.NPM_AUTH, 'base64').toString('utf8').split(':')
      res = request.sync.get encodeURI("https://goodeggs.registry.nodejitsu.com/#{moduleName}/latest"),
        auth: {user: auth[0], pass: auth[1]}
        json: true
      latestVersion = res.body.version

      trace "#{moduleName} latest version is #{latestVersion}"

      # first check shrinkwrap
      try
        json = JSON.parse(repoService.sync.getFile('npm-shrinkwrap.json').content())
        if shrinkwrapVersion = json.dependencies[moduleName]?.version
          valid = semver.satisfies latestVersion, shrinkwrapVersion
          trace "#{moduleName} is #{valid and 'valid' or 'invalid'}"
          continue
      catch e
        throw e unless e.code is 404

        # no shrinkwrap? check package.json
        json = JSON.parse(repoService.sync.getFile('package.json').content())
        if packageVersion = json.dependencies[moduleName]
          valid = semver.satisfies latestVersion, packageVersion
          trace "#{moduleName} is #{valid and 'valid' or 'invalid'}"
          continue

      trace "#{moduleName} is not a dependency"

  , (err) ->
    console.error(err.stack or err) if err?
    trace 'finished'

