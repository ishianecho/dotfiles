if filereadable(expand("~/.config/vim/autoload/plug.vim"))
  call plug#begin("~/.config/vim/plugged")
  Plug 'sainnhe/everforest'
  Plug 'airblade/vim-gitgutter'
  Plug 'junegunn/fzf.vim'
  call plug#end()

  silent! colorscheme everforest

  nnoremap <silent> <leader><Space> :Files<CR>
  nnoremap <silent> <leader>ff :Files<CR>
  nnoremap <silent> <leader>fg :GFiles<CR>
  nnoremap <silent> <leader>fc :Files ~/.config<CR>
  nnoremap <silent> <leader>fr :History<CR>
  nnoremap <silent> <leader>, :Buffers<CR>
  nnoremap <silent> <leader>fb :Buffers<CR>
  nnoremap <leader>/ :Rg<Space>
  nnoremap <leader>sg :Rg<Space>
  nnoremap <silent> <leader>sw :Rg <C-r><C-w><CR>
  xnoremap <silent> <leader>sw y:Rg <C-r>=substitute(@", '\n', '', 'g')<CR><CR>
  nnoremap <silent> <leader>sb :Lines<CR>
  nnoremap <silent> <leader>: :History:<CR>
  nnoremap <silent> <leader>sc :History:<CR>
  nnoremap <silent> <leader>s/ :History/<CR>
  nnoremap <silent> <leader>s" :Registers<CR>
  nnoremap <silent> <leader>sh :Helptags<CR>
  nnoremap <silent> <leader>sj :Jumps<CR>
  nnoremap <silent> <leader>sm :Marks<CR>
  nnoremap <silent> <leader>sk :Maps<CR>
  nnoremap <silent> <leader>sC :Commands<CR>
  nnoremap <silent> <leader>uC :Colors<CR>
  nnoremap <silent> <leader>gl :Commits<CR>
  nnoremap <silent> <leader>gf :BCommits<CR>
  nnoremap <silent> <leader>gb :Branches<CR>
  nnoremap <silent> <leader>gs :GFiles?<CR>
endif
