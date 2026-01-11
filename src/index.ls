module.exports =
  pkg:
    name: \@makeform/choice
    extend: name: \@makeform/common
    host: name: \@grantdash/composer
    i18n:
      en:
        "empty": "(empty)"
        "other": "Other"
        "fill-other": "Please fill"
        "edit options": "Edit Options"
        config:
          other:
            enabled: name: "enable 'other' option", desc: "show an 'other' option when enabled"
            editable: name: "input for other", desc: "show an text input for other value"
            requireOnCheck: name: "input required", desc: "text input is required when enabled"
          multiple: name: "multi-choice", desc: "user can choose multiple entries when enabled"
          sep: name: "separator", desc: "separator character for choices in view mode"
          layout: name: "layout", desc: "how widget is layouted"
      "zh-TW":
        "empty": "(未填寫)"
        "other": "其它"
        "fill-other": "請填寫"
        "edit options": "編輯清單"
        config:
          other:
            enabled: name: "使用「其它」選項", desc: "啟用時，顯示一個額外的「其它」選項"
            editable: name: "顯示輸入框", desc: "啟用時，提供一個供用戶填「其它」值的輸入框"
            requireOnCheck: name: "輸入框必填", desc: "若用戶勾選其它且輸入框有顯示，則輸入框必填"
          multiple: name: "多選", desc: "啟用時，用戶可進行多選"
          sep: name: "分隔字元", desc: "瀏覽模式下，顯示多選值時的分隔字元"
          layout: name: "排版", desc: "元件的排版方向"
  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt

mod = ({root, ctx, data, pubsub, parent, t, i18n}) ->
  {ldview} = ctx
  lc = {}
  hitf = ~> @hitf
  getv = (t) ~> if typeof(t) == \string => t else t?value or hitf!totext(t?label)
  # return value as a list regardless of original type ( doesn't include other.text )
  normv = ->
    vals = lc.value
    vals = if vals and vals.list => vals.list
    else if typeof(vals) == \string => [vals]
    else []
    return vals.filter(->it)
  getother = ~> (if lc.other.enabled => <[__other__]> else [])
  render-label = (opt) ~>
    s = opt.ctx
    s = if s == \__other__ => \other else if typeof(s) != \object => (s or '') else s.label
    if typeof(s) == \string => opt.node.textContent = t(s)
    else hitf!render(obj:->s)(opt)
  value-to-label = (v) ~>
    r = (lc[]values ++ getother!).filter(-> getkey(it) == v).0
    r = r?label or if r? => r else if v? => v
    if typeof(r) == \object => return hitf!totext(hitf!content(r))
    else if typeof(r) == \string => t(r) else (r or '')
  inside = (v) ~> v in (lc.values or []).map(-> getkey it) ++ getother!
  keygen = -> "#{Date.now!}-#{keygen.idx = (keygen.idx or 0) + 1}-#{Math.random!toString(36)substring(2)}"
  getkey = -> it.key or getv(it)
  pubsub.on \init.choice, (o) -> lc.defcfg = o
  @client = ->
    minibar: []
    meta: config:
      other:
        enabled: type: \boolean, name: "config.other.enabled.name", desc: "config.other.enabled.desc"
        editable: type: \boolean, name: "config.other.editable.name", desc: "config.other.editable.desc"
        requireOnCheck:
          type: \boolean, name: "config.other.requireOnCheck.name", desc: "config.other.requireOnCheck.desc"
      multiple:
        type: \boolean, name: "config.multiple.name", desc: "config.multiple.desc"
      sep: type: \text, name: "config.sep.name", desc: "config.sep.desc", default: \,
      layout:
        type: \choice
        name: "config.layout.name", desc: "config.layout.desc"
        values: <[row column]>
    render: ~> lc.view.render!; lc.option-view.render!
    sample: ~> config: values: [
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 1'
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 2'
      * key: keygen!, label: hitf!wrap "#{i18n.language}": 'Option 3'
      ]
  init: ->
    i18n.on \languageChanged, ~> _render-option!
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
      if !(lc.cfg.multiple or lc.other.enabled) =>
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
    lc.option-view = @mod.child.option-view = new ldview do
      root: root
      handler:
        chosen:
          list: ~>
            if typeof(v = @value!) == \string => [v]
            else if v => v.list or []
            else []
          key: -> getkey(it)
          view:
            action: click: "@": ({node, ctx}) ~> handler {value: getkey(ctx)}
            handler: label: ({node, ctx}) ~> render-label({node, ctx})
        option:
          list: ~>
            v = hitf!get!?config?values or []
            if !lc.defcfg?overwrite? or lc.defcfg.overwrite => if lc?defcfg?config?values => v = that
            ret = if Array.isArray(v) => v else if v => [v] else []
            if lc.kw =>
              ret = ret.filter (v) ->
                if v.keyword => return !!~(v.keyword).toLowerCase!.indexOf(lc.kw)
                !!~(v.label or v).toLowerCase!.indexOf(lc.kw) or
                !!~(v.value or '').toLowerCase!.indexOf(lc.kw)
            ret ++ getother!
          key: -> getkey(it)
          view:
            action: click: "@": ({node, ctx}) ~>
              handler {value: node.dataset.value}
            handler:
              "@": ({node, ctx}) ~>
                v = getkey(ctx)
                node.setAttribute \value, v
                node.dataset.value = v
                node.classList.toggle \active, (v in normv!)
                render-label({node, ctx})

    lc.view = @mod.child.view = view = new ldview do
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
          "add-option": ({node, views}) ~>
            new-entry = do
              key: keygen!
              label: hitf!wrap "#{i18n.language}": "untitled"
            hitf!get!{}config[]values.push new-entry
            hitf!set!
            views.0.render!
      init: ldcv: ({node}) ~> @mod.child.ldcv[node.dataset.name] = new ldcover root: node, resident: true
      text: content: ({node}) ~>
        if @is-empty! => return t(\empty)
        ret = @value!
        other = (ret or {}).other
        ret = if typeof(ret) == \string => [ret] else (ret.list or [])
        other-text = ''
        if ('__other__' in ret) and lc.other.enabled =>
          other-text = t("other")
          if (lc.other.editable or !(lc.other.editable?)) and (other or {}).text =>
            other-text += (":" + other.text)
        ret = ret
          .filter (v) -> v != \__other__
          .map (v) -> value-to-label(v)
        if lc.other.enabled and other-text => ret.push other-text
        ret = ret.join(if lc.cfg.sep => that else ', ')
        if !ret => ret = t("empty")
        return ret
      handler:
        "editable-option":
          list: ~> hitf!get!config?[]values
          key: -> getkey it
          view:
            action: click:
              text: hitf!edit do
                obj: ({ctx}) -> ctx.label = if typeof(ctx.label) == \string => {} else ctx{}label
              remove: ({node, ctx, views}) ~>
                cfg = hitf!get!{}config
                cfg.values = cfg.[]values.filter -> getkey(it) != getkey(ctx)
                hitf!set!
            handler: text: hitf!render obj: ({ctx}) -> ctx.label or ctx

        input: ({node}) ~>
          if lc.cfg.multiple => node.setAttribute \multiple, ''
          else node.removeAttribute \multiple
          if !hitf!get!readonly =>
            node.removeAttribute \readonly
            node.removeAttribute \disabled
          else
            node.setAttribute \readonly, null
            node.setAttribute \disabled, null
          vals = normv!
          for n in (node.options or []) => n.selected = n.value in vals
          node.classList.toggle \is-invalid, (@status! == 2 and (@errors!filter -> it != \fill-other).length)
        "other-text": ({node}) ~>
          if !lc.meta.readonly => node.removeAttribute \readonly
          else node.setAttribute \readonly, null
          vals = normv!
          show-other = lc.other.enabled and (lc.other.editable or !lc.other.editable?) and ("__other__" in vals)
          node.classList.toggle \d-none, !show-other
          node.value = ((lc.value or {}).other or {}).text or ''
          node.classList.toggle \is-invalid, @status! == 2 and (\fill-other in @errors!)
        "input-group": ({node}) ~>
          node.classList.toggle \layout-row, lc.cfg.layout == \row

  render: -> @mod.child.view.render!
  validate: ->
    Promise.resolve!then ~>
      if !hitf!get!config?other?require-on-check => return
      v = @value!
      if v and ((\__other__ in (v.list or [])) or v.other?enabled) and !v.other?text =>
        return ["fill-other"]
      return
