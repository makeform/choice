module.exports =
  pkg: name: "@makeform/choice", extend: name: '@makeform/common'
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  init: ->
    getv = (t) -> if typeof(t) == \object => t.value else t
    getlabel = (s) -> if typeof(s) == \object => t(s.label) else t(s)
    tolabel = (s) ->
      r = (lc.values or []).filter(-> getv(it) == s).0
      r = if r and r.label => r.label else r
      return if r => t(r) else s
    inside = (v) ~> v in (@mod.info.config.values or []).map(-> getv it)
    @on \change, ~> @mod.child.view.render <[input content]>
    handler = ({node}) ~> @value node.value
    @mod.child.view = view = new ldview do
      root: root
      action:
        input: input: handler
        change: input: handler
      text:
        content: ({node}) ~> if @is-empty! => 'n/a' else tolabel(@content!)
      handler:
        option:
          list: ~> @mod.info.config.values or []
          key: -> getv(it)
          view:
            handler:
              "@": ({node, ctx}) ~>
                node.setAttribute \value, getv(ctx)
                node.textContent = getlabel(ctx)
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

