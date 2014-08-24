Document = require("tree-sitter").Document
jsLanguage = require("tree-sitter-javascript")
TextBufferInput = require("./text-buffer-input")

module.exports =
class Controller
  constructor: (@workspaceView) ->

  start: ->
    @workspaceView.command "syntax-tree:select-up", => @selectUp()
    @workspaceView.command "syntax-tree:select-down", => @selectDown()
    @workspaceView.command "syntax-tree:select-left", => @selectLeft()
    @workspaceView.command "syntax-tree:select-right", => @selectRight()
    @workspaceView.command "syntax-tree:print-tree", => @printTree()

  stop: ->

  selectUp: ->
    @setUpDocument()

  selectDown: ->
    @setUpDocument()

  selectLeft: ->
    @setUpDocument()

  selectRight: ->
    @setUpDocument()

  printTree: ->
    console.log(@currentEditor().syntaxTreeDocument.toString())

  setUpDocument: ->
    editor = @currentEditor()
    unless editor.syntaxTreeDocument?
      editor.syntaxTreeDocument = new Document()
        .setLanguage(jsLanguage)
        .setInput(new TextBufferInput(editor.buffer))

      editor.buffer.on 'changed', ({ oldRange, newText, oldText }) ->
        editor.syntaxTreeDocument.edit
          position: editor.buffer.characterIndexForPosition(oldRange.start)
          bytesInserted: newText.length
          bytesRemoved: oldText.length

  currentEditor: ->
    @workspaceView.getActiveView().editor
