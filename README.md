# z~ettel~huyi.nvim

## Dependencies

Better workflow with `fzf.vim`:

```vim
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --bin' }
Plug 'junegunn/fzf.vim'
```

## Setup

- `g:zhuyi_path`

```vim
let g:zhuyi_path='~/zettel'
```

## Rest backend

- `g:zhuyi_backend`

```vim
" to use the rest calls
Plug 'hkupty/daedalus.nvim'

let g:zhuyi_backend='127.0.0.1:8000'
```

## Related

- [zhuyi-go](https://github.com/kraem/zhuyi-go)

## Inspiration

- [vimwiki](https://github.com/vimwiki/vimwiki)
- [vim-zettel](https://github.com/michal-h21/vim-zettel)
