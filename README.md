# z~ettel~huyi.nvim

## Dependencies

Depends on [zhuyi-go](https://github.com/kraem/zhuyi-go)

Better workflow with `fzf.vim`:

```vim
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
```

## Setup

- `g:zhuyi_path`
- `g:zhuyi_backend`

```vim
let g:zhuyi_path='~/zettel'
let g:zhuyi_backend='127.0.0.1:8000'
```
