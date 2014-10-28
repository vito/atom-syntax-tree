Document = require("tree-sitter").Document
goLanguage = require("tree-sitter-golang")
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
    @workspaceView.command "syntax-tree:toggle-debug", => @toggleDebug()

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
      depth = 0
      while node.parent() and !node.prev()
        depth++
        node = node.parent()
      node = node.prev()
      if node
        while depth > 0 and node.children.length > 0
          depth--
          node = node.children[node.children.length - 1]
      node

  selectRight: ->
    @updatedSelectedNode (node) ->
      depth = 0
      while node.parent() and !node.next()
        depth++
        node = node.parent()
      node = node.next()
      if node
        while depth > 0 and node.children.length > 0
          depth--
          node = node.children[0]
      node

  printTree: ->
    console.log(@getDocument(@currentEditor()).toString())

  toggleDebug: ->
    doc = @getDocument(@currentEditor())
    doc.setDebug (msg, params, type) ->
      switch type
        when 'parse'
          console.log("* ", msg, params)
        when 'lex'
          console.log("  ", msg, params)

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
    editor.scrollToScreenRange(editor.screenRangeForBufferRange(newRanges[0]))

  getDocument: (editor) ->
    editor.syntaxTreeDocument ?= do ->
      document = new Document()
        .setLanguage(goLanguage)
        .setInput(new TextBufferInput(editor.buffer))

      editor.buffer.onDidChange ({ oldRange, newRange, newText, oldText }) ->
        document.edit
          position: editor.buffer.characterIndexForPosition(oldRange.start)
          charsInserted: newText.length
          charsRemoved: oldText.length

      document

  currentEditor: ->
    @workspaceView.getActiveView().editor
