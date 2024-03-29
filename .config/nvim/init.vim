"unlet! skip_defaults_vim
"source $VIMRUNTIME/defaults.vim
set number relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set cc=81
highlight ColorColumn ctermbg=0
set hlsearch
":set shellcmdflag=-ci
let g:netrw_banner = 0
let g:netrw_liststyle = 3
set nostartofline

"Settings for the XDG locations
"set directory=~/.cache/vim,~/,/tmp
"set backupdir=~/.cache/vim,~/,/tmp
"set viminfo+=n~/.cache/vim/viminfo
"set runtimepath^=~/.config/vim
"set runtimepath+=~/.local/share/vim
"set runtimepath+=~/.config/vim/after
"set packpath^=~/.local/share/vim,~/.config/vim
"set packpath+=~/.config/vim/after,~/.local/share/vim/after
"set runtimepath=~/.config/vim,~/.config/vim/after,/var/lib/vim/addons,/etc/vim,/usr/share/vim/vimfiles,/usr/share/vim/vim91,/usr/share/vim/vimfiles/after,/etc/vim/after,/var/lib/vim/addons/after
"let $MYVIMRC="~/.config/vim/vimrc"
"let g:netrw_home = "~/.local/share/vim"

set background=dark

"Settings for Gruvbox (light)
"set termguicolors
"autocmd vimenter * ++nested colorscheme gruvbox
"let g:gruvbox_invert_selection=0
"set background=light

set laststatus=1
set titlestring=
set title

"Functions

function! ColorGruvboxl()
    set termguicolors
    colorscheme gruvbox
    let g:gruvbox_invert_selection=0
    set background=light
endfunction

function! ColorNord()
    set background=dark
    colorscheme nord
endfunction

"Default colorscheme function
"nnoremap <F2> :call ColorNord()<CR>

autocmd BufRead * autocmd FileType <buffer> ++once if &ft !~# 'commit\|rebase' && line("'\"") > 1 && line("'\"") <= line("$") | exe 'normal! g`"' | endif
source $HOME/.config/nvim/lua/init.lua
"set mouse=a
"vmap <LeftRelease> "*ygv
