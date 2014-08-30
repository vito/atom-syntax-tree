{WorkspaceView, EditorView, Point} = require 'atom'
Controller = require '../lib/controller'

describe "SyntaxTree", ->
  [workspaceView, controller, editorView] = []

  beforeEach ->
    workspaceView = new WorkspaceView
    controller = new Controller(workspaceView)
    controller.start()

    editorView = setUpActiveEditorView(workspaceView)
    editorView.editor.setText(trim("""
      var x = { theKey: "the-value" };
      console.log(x);
    """))

  describe "when a syntax-tree:select-up event is triggered", ->
    beforeEach ->
      editorView.editor.setCursorBufferPosition(new Point(0, "var x = { the".length))
      workspaceView.trigger 'syntax-tree:select-up'

    it "parses the document", ->
      programNode = editorView.editor.syntaxTreeDocument.children[0]
      expect(programNode.toString()).toEqual(trim("""
        (program
          (var_declaration (var_assignment
            (identifier)
            (object (pair (identifier) (string)))))
          (expression_statement (function_call
            (member_access (identifier) (identifier))
            (arguments (identifier)))))
      """))

    it "highlights the syntax node under the cursor", ->
      expect(editorView.editor.getSelectedText()).toEqual("theKey")

    describe "when select-up is triggered again", ->
      it "highlights the parent of the previously highlighted node", ->
        workspaceView.trigger 'syntax-tree:select-up'
        expect(editorView.editor.getSelectedText()).toEqual('theKey: "the-value"')

    describe "when select-down is triggered", ->
      it "highlights the first child of the previously highlighted node", ->
        workspaceView.trigger 'syntax-tree:select-up'
        workspaceView.trigger 'syntax-tree:select-down'
        expect(editorView.editor.getSelectedText()).toEqual('theKey')

    describe "when select-left is triggered", ->
      it "highlights the left sibling of the previously highlighted node", ->
        workspaceView.trigger 'syntax-tree:select-left'
        expect(editorView.editor.getSelectedText()).toEqual("x")

    describe "when select-right is triggered", ->
      it "highlights the left sibling of the previously highlighted node", ->
        workspaceView.trigger 'syntax-tree:select-right'
        expect(editorView.editor.getSelectedText()).toEqual('"the-value"')

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
            (var_declaration (var_assignment
              (identifier)
              (object (pair (identifier) (string)) (pair (identifier) (string)))))
            (expression_statement (function_call
              (member_access (identifier) (identifier))
              (arguments (identifier)))))
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
