" Vim can use per directory configuration files like this. 
" To enable that feature two lines are needed in your ~/.vimrc
" set exrc   " enables per-directory .vimrc files
" set secure   " disable unsafe commands in local .vimrc files
" Characters width is set to 109 for .c and XML but for everything else 79.
" If you update this file make sure to update .dir-locals.el & .editorconfig 

set tabstop=8
set shiftwidth=8
set expandtab
set makeprg=GCC_COLORS=\ make
set tw=79
au BufRead,BufNewFile *.xml set tw=109 shiftwidth=2 smarttab
au FileType sh set tw=80 shiftwidth=4 smarttab
au FileType c set tw=109
