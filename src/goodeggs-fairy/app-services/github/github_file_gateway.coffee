
class GithubFileGateway
  constructor: (@raw) ->
    # noop

  content: (encoding='utf8') ->
    new Buffer(@raw.content, @raw.encoding).toString(encoding)

module.exports = GithubFileGateway

