module.exports =
  pkg: name: "@makeform/choice", extend: name: '@makeform/common'
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  init: ->
    @on \change, ~>
      @mod.child.view.get(\input).value = it or ''
      @mod.child.view.render <[input content]>
    handler = ({node}) ~> @value node.value
    @mod.child.view = view = new ldview do
      root: root
      action:
        input: input: handler
        change: input: handler
      handler:
        content: ({node}) ~> if @is-empty! or typeof(v = @content!) != \string => \n/a else t(v)
        option:
          list: ~> @mod.info.config.values or []
          key: -> it
          handler: ({node, data}) ->
            node.setAttribute \value, data
            node.innerText = t data
        input: ({node}) ~>
          if !@mod.info.meta.readonly =>
            node.removeAttribute \readonly
            node.removeAttribute \disabled
          else
            node.setAttribute \readonly, null
            node.setAttribute \disabled, null
          node.value = @value!
          node.classList.toggle \is-invalid, @status! == 2

  render: -> @mod.child.view.render!

