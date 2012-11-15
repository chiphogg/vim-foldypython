" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-11-15
" URL: https://github.com/chiphogg/vim-foldypython

augroup pyformat
  autocmd!
  autocmd FileType python :call foldypython#AdaptTabStyle()
augroup END
