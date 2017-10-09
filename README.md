# swagger-jsdoc-edit

swagger-jsdoc-edit creates a workflow for editing yaml swagger path
partial entries written in jsdoc comment format. When the point is in
a jsdoc yaml comment, invoke `sje/edit-swagger` and we'll pop a new
buffer in yaml mode for you. Edit your yaml freely, validate
progressively with `sje/validate-swagger`, and when you're finished
with your edits, invoke `sje/update-swagger` to replace the old jsdoc
comment with the updated yaml, properly formatted and everything.

## usage

Define a keybind for the edit-shortcut, and then add a js2-mode hook
to turn on this mode:

```elisp
(require 'swagger-jsdoc-edit)
(setq sje/edit-shortcut (kbd "C-c C-n"))

(add-hook 'js2-mode-hook (lambda () (sje/js-mode t)))
```

after which, when you're in a js2-mode file, when you're in the middle
of a yaml swagger partial, hit the `sje/edit-shortcut` to pop out into
a separate buffer to edit yaml and validate some swagger `paths`
partials

In the new buffer, the following keybinds are available

| key                             | action               |
| ---                             | ---                  |
| M-s                             | sje/update-swagger   |
| C-c C-c (or whatever you chose) | sje/update-swagger   |
| C-c C-v                         | sje/validate-swagger |

If you have node's [`swagger-tools`][st] installed, we'll use that for
validation automatically before `sje/update-swagger`, or you can call
it directly as you work. When you're done editing the yaml, `C-c C-c`
in the edit buffer will bring you back to where you started.

[st]: https://github.com/apigee-127/swagger-tools
