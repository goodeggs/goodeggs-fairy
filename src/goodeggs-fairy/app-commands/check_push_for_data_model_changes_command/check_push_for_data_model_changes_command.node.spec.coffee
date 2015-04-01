require 'goodeggs-fairy/app-support/spec_helpers/node'
CheckPushForDataModelChangesCommand = require 'goodeggs-fairy/app-commands/check_push_for_data_model_changes_command'
GithubRepo = require 'goodeggs-fairy/app-services/github/github_repo'
emailer = require 'goodeggs-emailer'
makePushPayload = require './spec_fixtures/push'

describe 'CheckPushForDataModelChangesCommand', ->

  lazy 'payload', -> makePushPayload {@ref}
  lazy 'ref', -> 'refs/heads/master'
  {repo, command} = {}

  beforeEach (done) ->
    sinon.stub(emailer, 'send').yields()
    repo = sinon.createStubInstance GithubRepo
    command = new CheckPushForDataModelChangesCommand {repo, @payload}
    command.run done

  describe 'a push to a branch', ->
    lazy 'ref', -> 'refs/heads/foobar'

    it 'is ignored', ->
      expect(emailer.send).not.to.have.been.called

