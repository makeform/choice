# Change Logs

## v4.0.1

 - use cps-hover-host and cps-hover-reveal to replace cps-hover class


## v4.0.0

 - support @grantdash/composer host
 - ensure error information is shown correctly in corresponding field, either select or input box.
 - show error about fill other only if other is chosen


## v3.0.0

 - change default value of `other.editable` to `true`.
   in similar widgets, enable `other` always brings up a edit field. Use default `true` value maintains the consistency and still keep the flexibility to turn it off.


## v2.1.0

 - support `chosen` selector for list of selected items
 - tweak content selector for single / multiple choices


## v2.0.1

 - fix bug: content in view mode isn't translated


## v2.0.0

 - support object values
 - tweak DOM based on updated `@makeform/common` DOM structure.
 - support multiple choice
 - support `other` and toggling other text field
 - support inline / block display with different multiple / other configuration
 - support ldcover-based editing mechanism
 - support configuration overridding from subblock via `init.choice` pubsub event.
 - support custom separator in view mode


## v1.0.3

 - ensure translated value to be string, otherwise `n/a` will be shown.


## v1.0.2

 - release missing dist file


## v1.0.1

 - use `mf-note` to replace styling in note-related tag.
 - add `limitation`, `note` and `error` selector


## v1.0.0

 - init release

