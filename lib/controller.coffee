Document = require("tree-sitter").Document
jsLanguage = require("tree-sitter-javascript")
TextBufferInput = require("./text-buffer-input")
{Range} = require("atom")

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
    editor = @currentEditor()
    buffer = editor.buffer
    newRanges = for range in editor.getSelectedBufferRanges()
      node = editor.syntaxTreeDocument.nodeAt(
        buffer.characterIndexForPosition(range.start),
        buffer.characterIndexForPosition(range.end)
      )
      new Range(
        buffer.positionForCharacterIndex(node.position),
        buffer.positionForCharacterIndex(node.position + node.size),
      )
    editor.setSelectedBufferRanges(newRanges)

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
