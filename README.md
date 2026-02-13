# Telescope Context

A Neovim plugin to manage named contexts and locations with Telescope integration.


## Motivation

Nvim's builtin marks feature works fine when there is not a lot of locations to keep track of. But when things get complicated, it's easy to forget which mark corresponds to which context. I needed a way to associate a mark with some semantics.

This plugin brings two concepts: Context and Location. A Context is a list of Locations, a Location is a tuple of name and a mark to jump to. You can switch among locations with a telescope picker UI.


## Installation

Using packer.nvim:

```lua
use { 'ailrk/telescope-context.nvim'}
```

Ensure Telescope is installed and loaded.


## Commands

### Create a context

```
:CtxCreate <context_name>
```

Creates a new context to group locations.


### Delete a context

```
:CtxDelete <context_name>
```

Deletes a context and all its locations.


### Add a location

```
:CtxAdd <context_name> <location_name>
```

Adds the current cursor position as a named location to a context.


### List context or locations

```
:CtxLs <context_name>
```

* No argument: lists all contexts in Telescope. Selecting one opens its locations.
* With argument: directly opens Telescope for the specified context's locations.

Inside Telescope:

* <Enter> → jump to context/location
* <C-d> → delete selected context/location


### List locations from the last context

```
:CtxLast
```

List locations of the latest accessed context.


## Recommended keymaps

```lua
vim.keymap.set('n', '<space>cz', ':CtxLast<CR>', { desc = 'List locations in the last context' })
vim.keymap.set('n', '<space>cl', ':CtxLs ', { desc = 'List context/location' })
vim.keymap.set('n', '<space>ca', ':CtxAdd ', { desc = 'Add location to context' })
vim.keymap.set('n', '<space>cc', ':CtxCreate ', { desc = 'Create context' })
```

## Notes

* Locations store file, line, column, and a label.
* Fully integrated with Telescope for interactive selection and jumping.
* Supports local development and can be loaded via a local directory with packer.nvim.
