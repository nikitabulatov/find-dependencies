{SelectListView} = require('atom-space-pen-views')

module.exports = class FindModulesView extends SelectListView
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

  viewForItem: ({name}) ->
    "<li>#{name}</li>"

  confirmed: ({dir}) ->
    @hide()
    atom.workspace.open(dir)

  cancelled: ->
    @hide()
