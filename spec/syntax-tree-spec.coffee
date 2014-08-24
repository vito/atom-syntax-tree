{WorkspaceView, EditorView, Point} = require 'atom'
Controller = require '../lib/controller'

describe "SyntaxTree", ->
  [workspaceView, controller, editorView] = []

  beforeEach ->
    workspaceView = new WorkspaceView
    editorView = setUpActiveEditorView(workspaceView)
    controller = new Controller(workspaceView)
    controller.start()

    editorView.editor.setText(trim("""
      var x = { theKey: "the-value" };
      console.log(x);
    """))

  describe "when a syntax-tree:select-* event is triggered", ->
    beforeEach ->
      workspaceView.trigger 'syntax-tree:select-up'

    it "parses the document", ->
      programNode = editorView.editor.syntaxTreeDocument.children[0]
      expect(programNode.toString()).toEqual(trim("""
        (program
          (var_declaration
            (identifier)
            (object (identifier) (string)))
          (expression_statement (function_call
            (member_access (identifier) (identifier))
            (identifier))))
      """))

    describe "when the document is edited", ->
      beforeEach ->
        editorView.editor.buffer.insert(
          new Point(0, 'var x = { theKey: "the-value"'.length),
          ', otherKey: "other-value" '
        )

      it "updates the parse tree", ->
        programNode = editorView.editor.syntaxTreeDocument.children[0]
        expect(programNode.toString()).toEqual(trim("""
          (program
            (var_declaration
              (identifier)
              (object (identifier) (string) (identifier) (string)))
            (expression_statement (function_call
              (member_access (identifier) (identifier))
              (identifier))))
        """))

# Helpers

setUpActiveEditorView = (parentView) ->
  editorView = new EditorView(mini: true)
  spyOn(parentView, 'getActiveView').andReturn(editorView)
  editorView

trim = (string) ->
  string
    .replace(/\n/g, '')
    .replace(/\s+/g, " ")
    .trim()