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
    @updatedSelectedNode (node, start, end) ->
      while (node.position == start) && (node.position + node.size == end) && node.parent()
        node = node.parent()
      node

  selectDown: ->
    @updatedSelectedNode (node) ->
      node.children[0]

  selectLeft: ->
    @updatedSelectedNode (node) ->
      while node.parent() and not node.prev()
        node = node.parent()
      node.prev()

  selectRight: ->
    @updatedSelectedNode (node) ->
      while node.parent() and not node.next()
        node = node.parent()
      node.next()

  printTree: ->
    console.log(@currentEditor().syntaxTreeDocument.toString())

  updatedSelectedNode: (fn) ->
    editor = @currentEditor()
    buffer = editor.buffer
    document = @getDocument(editor)
    newRanges = for range in editor.getSelectedBufferRanges()
      currentStart = buffer.characterIndexForPosition(range.start)
      currentEnd = buffer.characterIndexForPosition(range.end)
      node = document.nodeAt(currentStart, currentEnd - 2)
      newNode = fn(node, currentStart, currentEnd)
      if newNode
        new Range(
          buffer.positionForCharacterIndex(newNode.position),
          buffer.positionForCharacterIndex(newNode.position + newNode.size),
        )
      else
        range
    editor.setSelectedBufferRanges(newRanges)

  getDocument: (editor) ->
    editor.syntaxTreeDocument ?= do ->
      document = new Document()
        .setLanguage(jsLanguage)
        .setInput(new TextBufferInput(editor.buffer))
      editor.buffer.on 'changed', ({ oldRange, newText, oldText }) ->
        document.edit
          position: 0
          bytesInserted: 0
          bytesRemoved: 0
      document

  currentEditor: ->
    @workspaceView.getActiveView().editor
