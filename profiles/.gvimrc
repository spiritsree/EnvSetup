" -----------------------------------------------------------
"  GRAPHICAL
" -----------------------------------------------------------
"
winpos 0 0

set background=dark

" Use 14pt Monaco
set guifont=Monaco:h14

" Don’t blink cursor in normal mode
set guicursor=n:blinkon0

" Better line-height
set linespace=8

set gfn=Menlo:h14
set anti               " antialiasing
set guioptions=gemc
set columns=104
set lines=61
set ch=4

" puts external commands through a pipe instead of a pseudo-tty:
" set noguipty

" put the * register on the system clipboard
set clipboard+=unnamed

" -----------------------------------------------------------
"  TABS
" -----------------------------------------------------------

set guitablabel=%N\ %t\ %m

" C-TAB and C-SHIFT-TAB cycle tabs forward and backward
nmap <c-tab> :tabnext<cr>
imap <c-tab> <c-o>:tabnext<cr>
vmap <c-tab> <c-o>:tabnext<cr>
nmap <c-s-tab> :tabprevious<cr>
imap <c-s-tab> <c-o>:tabprevious<cr>
vmap <c-s-tab> <c-o>:tabprevious<cr>

" C-# switches to tab
nmap <d-1> 1gt
nmap <d-2> 2gt
nmap <d-3> 3gt
nmap <d-4> 4gt
nmap <d-5> 5gt
nmap <d-6> 6gt
nmap <d-7> 7gt
nmap <d-8> 8gt
nmap <d-9> 9gt


hi def link coffeeSpecialVar Type
