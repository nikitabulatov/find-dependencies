{SelectListView} = require('atom-space-pen-views')

module.exports = class FindDependenciesView extends SelectListView
  initialize: ->
    super
    @addClass('overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

  show: ->
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel.hide()

  isVisible: ->
    @panel.isVisible()

  viewForItem: ({name, rootDir}) ->
    "<li>#{name} <small style='font-size: 8px;'>(from #{rootDir})</small></li>"

  confirmed: ({filePath}) ->
    @hide()
    atom.workspace.open(filePath)
    setTimeout(->
      atom.commands.dispatch(atom.views.getView(atom.workspace), 'tree-view:reveal-active-file')
    , 50)

  getFilterKey: ->
    'name'

  cancelled: ->
    @hide()
