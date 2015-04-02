require 'goodeggs-fairy/app-support/spec_helpers/node'
CheckPushForDataModelChangesCommand = require 'goodeggs-fairy/app-commands/check_push_for_data_model_changes_command'
RepoHelper = require 'goodeggs-fairy/app-commands/check_push_for_data_model_changes_command/repo_helper'
GithubRepo = require 'goodeggs-fairy/app-services/github/github_repo'
emailer = require 'goodeggs-emailer'
makePushPayload = require './spec_fixtures/push'
makeDiffPayload = require './spec_fixtures/diff'

describe 'CheckPushForDataModelChangesCommand', ->

  lazy 'payload', -> makePushPayload {@ref}
  {repo, command} = {}

  beforeEach ->
    @sinon.stub(emailer, 'send').yields()
    repo = sinon.createStubInstance GithubRepo
    repo.owner = 'goodeggs'
    repo.name = 'garbanzo'
    command = new CheckPushForDataModelChangesCommand {repo, @payload}

  describe 'a push to a branch', ->
    lazy 'ref', -> 'refs/heads/foobar'

    beforeEach ->
      command.sync.run()

    it 'is ignored', ->
      expect(emailer.send).not.to.have.been.called

  describe 'a push to master', ->
    lazy 'ref', -> 'refs/heads/master'

    describe 'with a model file', ->

      beforeEach ->
        @sinon.stub(RepoHelper::, 'fileHasModel').yields(null, true)

      describe 'that was added', ->
        beforeEach ->
          repo.compareCommits.yields null, makeDiffPayload(status: 'added')
          command.sync.run()

        it 'checks the file at the after commit for models', ->
          expect(RepoHelper::fileHasModel).to.have.been.calledOnce
          expect(RepoHelper::fileHasModel).to.have.been.calledWith 'src/nettle/server/jobs/product_constraint_failure_reporter.coffee', @payload.after

        it 'emails', ->
          expect(emailer.send).to.have.been.calledOnce
          expect(emailer.send).to.have.been.calledWithMatch
            to: 'rothfels <john.rothfels@gmail.com>'
            cc: 'delivery-eng@goodeggs.com, John Rothfels <john.rothfels@gmail.com>'
            subject: "Data model changes in goodeggs/garbanzo src/nettle/server/jobs/product_constraint_failure_reporter.coffee push f93e0fb"

