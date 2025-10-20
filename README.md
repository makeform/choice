# @makeform/choice

Dropdown style widget for users to make one single choice between multiple options.


## Configs

 - `values`: Array of string for options in this widget.
 - `multiple`: default false. when set to true, allow multiple choices
 - `other`: an object with following fields, for configuration of custom data:
   - `enabled`: show a dedicated `other` option.
   - `editable`: show a text field when `other` is chosen. default true if omitted
   - `requireOnCheck`: default false. when set to true, text field for `other` must not empty if `other` is chosen.
 - `sep`: default `,`. text separator for joining values from multiple choice in view mode.
 - `layout`: either `row` or `column`. default `column`. decide how to layout text field for `other` and select widget.
 


## Extension

use `init.choice` event with `{config: { ... }}` parameter to create a new widget based on certain configuration. For example:

    module.exports =
      pkg: extend: name: "@makeform/choice"
      init: ({pubsub}) -> pubsub.fire \init.choice, config: values: <[Apple Orange Banana]>

Specified configurations won't be overrided by users so always predefine a config if you don't want user to change its value.


## License

MIT
