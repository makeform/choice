module.exports =
  pkg:
    name: "@makeform/choice", extend: name: '@makeform/common'
    i18n:
      en:
        "empty": "(empty)"
        "other": "Other"
        "fill-other": "Please fill"
      "zh-TW":
        "empty": "(未填寫)"
        "other": "其它"
        "fill-other": "請填寫"
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)
mod = ({root, ctx, data, pubsub, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  pubsub.on \init.choice, (o) -> lc.defcfg = o
  init: ->
    i18n.on \languageChanged, ~> _render-option!
    getv = (t) -> if typeof(t) == \object => t.value else t
    # return value as a list regardless of original type
    # ( doesn't include other.text )
    normv = ->
      vals = lc.value
      vals = if vals and vals.list => vals.list
      else if typeof(vals) == \string => [vals]
      else []
      return vals.filter(->it)
    getother = ~>
      (if lc.other.enabled => <[__other__]> else [])
    getlabel = (s) ->
      if s == \__other__ => t(\other)
      else if typeof(s) == \object => t(s.label) else t(s)
    tolabel = (s) ->
      r = (lc.values ++ getother!).filter(-> getv(it) == s).0
      r = if r and r.label => r.label else r
      return if r => t(r) else s
    inside = (v) ~> v in (lc.values or []).map(-> getv it) ++ getother!
    _render-option = debounce 100, ~> if @mod.child.option-view => @mod.child.option-view.render!
    remeta = ~>
      if !lc.defcfg => cfg = @mod.info.config or {}
      else
        cfg = {} <<< (lc.defcfg.config or {})
        for k,v of @mod.info.config => if !cfg[k]? => cfg[k] = v
      lc.meta = @mod.info.meta
      lc.cfg = cfg
      lc.other = cfg.{}other
      lc.values = cfg.values or []
      if @mod.child.view => @mod.child.view.render!
      _render-option!
    remeta!
    @on \meta, ~> remeta!
    @on \change, (v) ~>
      lc.value = (v or {})
      lc.value.list = lc.value.[]list.filter -> inside(it)
      @mod.child.view.render <[input content other-text]>
      _render-option!

    handler = ({select, value, other}) ~>
      if !(lc.cfg.multiple and lc.other.enabled) =>
        if select => return @value (lc.value = select.value)
        else if value => return @value(lc.value = value or '')
      if !lc.value? => lc.value = {list: []}
      else if typeof(lc.value) == \string => lc.value = {list: [lc.value].filter(->it)}
      if select =>
        if !lc.cfg.multiple => lc.value.list = [select.value].filter(->it)
        else
          selected = Array.from(select.selectedOptions).map(->it.value).filter(->it)
          lc.value = {list: selected}
      else if value =>
        if ~(idx = lc.value.list.indexOf(value)) => lc.value.list.splice idx, 1
        else lc.value.list.push value
      else if other? and lc.other.enabled => lc.value.{}other.text = other
      @value lc.value

    search = debounce 150, ({kw} = {}) ~>
      lc.kw = "#{kw or ''}".toLowerCase!
      @mod.child.option-view.render \option

    @mod.child.ldcv = {}
    @mod.child.option-view = new ldview do
      root: root
      handler:
        option:
          list: ~>
            ret = lc.values
            if lc.kw =>
              ret = ret.filter (v) ->
                if v.keyword => return !!~(v.keyword).toLowerCase!.indexOf(lc.kw)
                !!~(v.label or v).toLowerCase!.indexOf(lc.kw) or
                !!~(v.value or '').toLowerCase!.indexOf(lc.kw)
            ret ++ getother!
          key: -> getv(it)
          view:
            action: click: "@": ({node, ctx}) ~>
              handler {value: node.dataset.value}
            handler:
              "@": ({node, ctx}) ~>
                v = getv(ctx)
                node.setAttribute \value, v
                node.dataset.value = v
                node.textContent = getlabel(ctx)
                node.classList.toggle \active, (v in normv!)

    @mod.child.view = view = new ldview do
      root: root
      action:
        input:
          search: ({node}) -> search {kw: node.value}
          input: ({node}) -> handler {select: node}
          "other-text": ({node}) -> handler {other: node.value}
        change:
          search: ({node}) -> search {kw: node.value}
          input: ({node}) -> handler {select: node}
          "other-text": ({node}) -> handler {other: node.value}
        click:
          toggle: ({node}) ~> @mod.child.ldcv[node.dataset.name].toggle!
          reset: ({node}) ~>
            lc.value = null
            handler {}
      init: ldcv: ({node}) ~> @mod.child.ldcv[node.dataset.name] = new ldcover root: node, resident: true
      text: content: ({node}) ~>
        if @is-empty! => return t(\empty)
        if !(lc.cfg.multiple or lc.other.enabled) => return @content!
        ret = @value!
        other = (ret or {}).other
        ret = if typeof(ret) == \string => [ret] else (ret.list or [])
        other-text = ''
        if ('__other__' in ret) and lc.other.enabled =>
          other-text = t("other")
          if lc.other.editable and (other or {}).text =>
            other-text += (":" + other.text)
        ret = ret
          .filter (v) -> v != \__other__
          .map (v) -> tolabel(v)
        if other-text => ret.push other-text
        ret = ret.join(', ')
        if !ret => ret = t("empty")
        return ret
      handler:
        input: ({node}) ~>
          if lc.cfg.multiple => node.setAttribute \multiple, ''
          else node.removeAttribute \multiple
          if !@mod.info.meta.readonly =>
            node.removeAttribute \readonly
            node.removeAttribute \disabled
          else
            node.setAttribute \readonly, null
            node.setAttribute \disabled, null
          vals = normv!
          for n in (node.options or []) => n.selected = n.value in vals
          node.classList.toggle \is-invalid, @status! == 2
        "other-text": ({node}) ~>
          if !lc.meta.readonly => node.removeAttribute \readonly
          else node.setAttribute \readonly, null
          vals = normv!
          show-other = lc.other.enabled and lc.other.editable and ("__other__" in vals)
          node.classList.toggle \d-none, !show-other
          node.value = ((lc.value or {}).other or {}).text or ''
        "input-group": ({node}) ~>
          node.classList.toggle \layout-row, lc.cfg.layout == \row

  render: -> @mod.child.view.render!
  validate: ->
    Promise.resolve!then ~>
      if !((@mod.info.config or {}).other or {}).require-on-check => return
      v = @value!
      if v and (v.other or {}).enabled and !(v.other or {}).text =>
        return ["other-error"]
      return
