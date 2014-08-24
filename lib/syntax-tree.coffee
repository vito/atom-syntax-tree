Controller = require './controller'

module.exports =
  syntaxTreeView: null

  activate: (state) ->
    @controller = new Controller(atom.workspaceView)
    @controller.start()

  deactivate: ->
    @syntaxTreeView.stop()

  serialize: ->
    {}
