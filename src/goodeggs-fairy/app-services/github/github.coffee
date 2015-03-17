GitHubClient = require 'github'

GithubRepo = require './github_repo'

class Github

  constructor: (bot) ->
    @_client = new GitHubClient
      version: '3.0.0'
      timeout: 5000
      headers:
        'user-agent': 'goodeggs-fairy'
    auth = switch bot.options.auth
      when 'basic'
        type: 'basic'
        username: bot.options.username
        password: bot.options.password
      when 'oauth'
        type: 'oauth'
        token: bot.options.password
      else
        throw new Error("unknown auth type '#{bot.options.auth}'")
    @_client.authenticate auth

  repo: ({owner, name}) ->
    new GithubRepo @_client, {owner, name}

module.exports = Github

