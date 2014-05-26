{$, View} = require 'atom'

DataResultView = require './data-result-view'
HeaderView = require './header-view'
NewConnectionView = require './new-connection-view'
DbFactory = require './data-managers/db-factory'

module.exports =
class DataAtomView extends View
   @content: ->
      @div class: 'data-atom tool-panel panel panel-bottom padding native-key-bindings', =>
         @div class: 'resize-handle'
         @subview 'headerView', new HeaderView()
         @subview 'resultView', new DataResultView()

   initialize: (serializeState) ->
      atom.workspaceView.command "data-atom:execute", => @execute()
      atom.workspaceView.command 'data-atom:toggle-results-view', => @toggleView()

      @on 'mousedown', '.resize-handle', (e) => @resizeStarted(e)

   # Returns an object that can be retrieved when package is activated
   serialize: ->

   # Tear down any state and detach
   destroy: ->
      @detach()

   toggleView: ->
      if @hasParent()
         #stop()
         @detach()
      else
         atom.workspaceView.prependToBottom(this)
         @resultView.updateHeight(@height() - @headerView.height() - 20)

   resizeStarted: =>
      $(document.body).on('mousemove', @resizeTreeView)
      $(document.body).on('mouseup', @resizeStopped)

   resizeStopped: =>
      $(document.body).off('mousemove', @resizeTreeView)
      $(document.body).off('mouseup', @resizeStopped)

   resizeTreeView: ({pageY}) =>
      height = $(document.body).height() - pageY
      @height(height)
      @resultView.updateHeight(@height() - @headerView.height() - 20)

   execute: ->
      if !@dataManager
         # prompt for a connection
         ncv = new NewConnectionView((url) =>
            @dataManager = DbFactory.createDataManagerForUrl(url)
            @actuallyExecute())
         ncv.show()
      else
         @actuallyExecute()

   actuallyExecute: ->
      @toggleView() if !@hasParent()

      #clear results view and show things are happening
      @resultView.clear()

      editor = atom.workspace.getActiveEditor()
      query = if editor.getSelectedText() then editor.getSelectedText() else editor.getText()

      @dataManager.execute query
      , (result) =>
         if result.message
            @resultView.setMessage(result.message)
         else
            @resultView.setResults(result)
      , (err) =>
         @resultView.setMessage(err)
         @dataManager = null
