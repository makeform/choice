# @makeform/choice

Dropdown style widget for users to make one single choice between multiple options.


## Configs

 - `values`: Array of string for options in this widget.


## Extension

use `init.choice` event with `{config: { ... }}` parameter to create a new widget based on certain configuration. For example:

    module.exports =
      pkg: extend: name: "@makeform/choice"
      init: ({pubsub}) -> pubsub.fire \init.choice, config: values: <[Apple Orange Banana]>

Specified configurations won't be overrided by users so always predefine a config if you don't want user to change its value.


## License

MIT
