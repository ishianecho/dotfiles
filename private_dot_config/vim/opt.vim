set encoding=utf-8
syntax on

set title
set titlestring=VIM:\ %f
set number
set relativenumber
set ruler
set signcolumn=yes
set cursorline
set showmatch

set tabstop=2
set shiftwidth=2
set expandtab

set wrap
set breakindent
set linebreak
set colorcolumn=0
set textwidth=0
set wrapmargin=0

set foldcolumn=1
set foldlevel=99
set foldlevelstart=99
set foldenable
set fillchars=eob:\ ,fold:\ ,foldopen:-,foldsep:\ ,foldclose:+

set laststatus=3
set showtabline=2

if has("clipboard")
  set clipboard=unnamedplus
endif
set autowrite
set incsearch
set updatetime=600
set timeoutlen=400
set sessionoptions=globals,blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions

set mouse=a
set mousefocus
set mousehide

set splitkeep=screen
set termguicolors
set background=light
let &scrolloff = float2nr(&lines * 0.2)
set diffopt=filler,context:3,internal,algorithm:patience
set viminfofile=~/.config/vim/viminfo

let g:mapleader = " "
