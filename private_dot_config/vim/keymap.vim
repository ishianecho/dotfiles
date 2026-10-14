autocmd BufRead,BufNewFile *.json setfiletype jsonc

function! s:SmartBd() abort
  let l:buf = bufnr()
  if getbufvar(l:buf, '&buftype') ==# 'terminal'
    execute 'bdelete!' l:buf
    return
  endif
  let l:bufs = filter(range(1, bufnr('$')), 'bufloaded(v:val) && buflisted(v:val)')
  if len(l:bufs) <= 1
    enew
    execute 'bdelete' l:buf
    return
  endif
  let l:idx = index(l:bufs, l:buf)
  let l:next = l:bufs[(l:idx + 1) % len(l:bufs)]
  execute 'buffer' l:next
  execute 'bdelete' l:buf
endfunction

function! s:SmartClose() abort
  if winnr('$') > 1
    close
  else
    call s:SmartBd()
  endif
endfunction

function! s:SwapBuf(dir) abort
  let l:curwin = winnr()
  let l:curbuf = bufnr()
  execute 'wincmd' a:dir
  if winnr() == l:curwin
    return
  endif
  let l:other = bufnr()
  execute 'buffer' l:curbuf
  execute l:curwin . 'wincmd w'
  execute 'buffer' l:other
endfunction

inoremap jj <Esc>
cnoremap jj <C-c>

nnoremap <silent> <leader>w :w<CR>
nnoremap <silent> <leader>z :qa<CR>

nnoremap <silent> <leader>en :enew<CR>
nnoremap <silent> [b :bprev<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> <leader>bl :b#<CR>
nnoremap <silent> <leader>bd :call <SID>SmartBd()<CR>
nnoremap <silent> <leader>bc :let @+=expand("%:~:.")<CR>
nnoremap <silent> <leader>bC :let @+=expand("%:p")<CR>
nnoremap <leader>ee :edit<Space>

nnoremap <silent> [<Tab> :tabprevious<CR>
nnoremap <silent> ]<Tab> :tabnext<CR>
nnoremap <silent> <leader><Tab>d :tabclose<CR>
nnoremap <leader><Tab><Tab> :tabnew<Space>

nnoremap <leader>V :split<Space>
nnoremap <leader>v :vsplit<Space>
nnoremap <silent> <leader>- :split<CR>
nnoremap <silent> <leader><Bar> :vsplit<CR>
nnoremap <silent> <leader>q :call <SID>SmartClose()<CR>
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l
nnoremap <silent> <M-h> :vertical resize -2<CR>
nnoremap <silent> <M-l> :vertical resize +2<CR>
nnoremap <silent> <M-j> :resize +2<CR>
nnoremap <silent> <M-k> :resize -2<CR>
nnoremap <silent> <leader>H :call <SID>SwapBuf("h")<CR>
nnoremap <silent> <leader>J :call <SID>SwapBuf("j")<CR>
nnoremap <silent> <leader>K :call <SID>SwapBuf("k")<CR>
nnoremap <silent> <leader>L :call <SID>SwapBuf("l")<CR>

nnoremap <silent> <leader>ur :redraw<Bar>nohlsearch<Bar>diffupdate<CR>
nnoremap <silent> <leader>uc :let &background=(&background ==# "light" ? "dark" : "light")<CR>

nnoremap <silent> ]] :call search('\\<'.expand('<cword>').'\\>', 'W')<CR>
nnoremap <silent> [[ :call search('\\<'.expand('<cword>').'\\>', 'bW')<CR>

tnoremap <C-q> <C-\><C-n>
