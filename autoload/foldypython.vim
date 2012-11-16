" Vim script
" Author: Charles Hogg <charles.r.hogg@gmail.com>
" Last Change: 2012-11-13
" URL: https://github.com/chiphogg/vim-foldypython

" Utility Functions {{{1
" SECTION: Preserve cursor position, etc. {{{2

" Adapted from:
" https://gist.github.com/2973488/222649d4e7f547e16c96e1b9ba56a16c22afd8c7

function! s:PreserveStart()
  let b:PRESERVE_search = @/
  let b:PRESERVE_cursor = getpos(".")
  normal! H
  let b:PRESERVE_window = getpos(".")
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! s:PreserveFinish()
  let @/ = b:PRESERVE_search
  call setpos(".", b:PRESERVE_window)
  normal! zt
  call setpos(".", b:PRESERVE_cursor)
endfunction

function! s:Preserve(command)
  call s:PreserveStart()
  execute a:command
  call s:PreserveFinish()
endfunction

" END Utility Functions }}}1

" FUNCTION: s:FirstLineInClass {{{1
" Is this line number the first line in a class?
"
" Args:
" l_num: A line number in the current file
"
" Return:
" 1 if the preceding line opens a new class; 0 otherwise
function! s:FirstLineInClass(l_num)
  return a:l_num > 1 && s:IsClass(getline(a:l_num - 1))
endfunction

" FUNCTION: s:Indent {{{1
" The number of shiftwidths this line is indented
"
" Args:
" l_num: A line number in the current file
"
" Return:
" The opening whitespace divided by the shiftwidth
function! s:Indent(l_num)
  return indent(a:l_num) / &shiftwidth
endfunction

" FUNCTION: s:IsClass {{{1
" Is this line of text a class definition?
"
" Args:
" line: A string (presumably a line of text from a source code file)
"
" Return:
" 1 if this line is a class definition, 0 otherwise
function! s:IsClass(line)
  return a:line =~# '\v^\s*class\s'
endfunction

" FUNCTION: s:IsDef {{{1
" Is this line of text a function definition?
"
" Args:
" line: A string (presumably a line of text from a source code file)
"
" Return:
" 1 if this line is a function definition, 0 otherwise
function! s:IsDef(line)
  return a:line =~# '\v^\s*def\s'
endfunction

" FUNCTION: s:LastLineBeforeClass {{{1
" Is this line number the last line before a class?
"
" Args:
" l_num: A line number in the current file
"
" Return:
" 1 if the next line opens a new class; 0 otherwise
function! s:LastLineBeforeClass(l_num)
  return a:l_num < line("$") && s:IsClass(getline(a:l_num + 1))
endfunction

" FUNCTION: s:PrevLessIndentedMatch {{{1
" The previous line which matches a given pattern and is indented by less than
" the given amount.
"
" Args:
" TODO
"
" Return:
" TODO
function! s:PrevLessIndentedMatch(pattern, indent)
  " Save the search buffer (don't want to clobber it!)
  let l:old_search = @/
  let l:old_line = line(".")

  " Goto the previous definition with smaller indent
  let l:pattern = '\v(^\s{'.a:indent.'})@<!'.a:pattern
  let l:result = -1
  try
    exe "norm ?".l:pattern."\<CR>"
    if line(".") < l:old_line
      let l:result = line(".")
    endif
  endtry

  " Go back where we were and restore search buffer
  exe "norm \<C-O>"
  let @/ = l:old_search

  return l:result
endfunction

" FUNCTION: foldypython#AdaptTabStyle {{{1
" Make an educated guess about the tab width coding convention, then set
" parameters accordingly.
"
" This function reads through the file and tries to guess the number of spaces
" per tab.  It then sets the shiftwidth to match and recomputes all the folds.
function! foldypython#AdaptTabStyle()
  call s:PreserveStart()

  " Set shiftwidth to match first indented non-blank line
  " (We have to be careful to disable folds while we search!
  " Lines hiding inside a fold don't get detected.)
  let l:fold_status = &foldenable
  set nofoldenable
  try
    " Basically, go to the first line which
    "   a) begins with a block-beginning keyword,
    "   b) ends with a colon, and
    "   c) is followed by an *indented* non-blank line.
    " If we find such a line, assume its indent reflects the coding style.
    " NOTE: the list of block-beginning keywords is by no means exhaustive!
    " I just hacked it together quick-and-dirty.
    let l:kw = '(class|def|if|for|while|try|except|finally)'
    silent exe "normal! gg/\\v^".l:kw.".*:\\s*$\\_.\\s+\\S\<CR>j"
    silent exe "setlocal shiftwidth=".indent(".")
  endtry
  let &foldenable = l:fold_status

  " recompute folds
  normal! zx

  call s:PreserveFinish()
endfunction

" FUNCTION: foldypython#FoldLevel {{{1
" The foldlevel for a line in a python file.
"
" See ":help fold-expr".
" I want "class" to fold everything *under* the definition line (and leave a
" single blank line above and below), and "def" to fold everything *including*
" the definition line (*without* excluding blank lines).
"
" Return:
" The desired foldlevel for this line
function! foldypython#FoldLevel(l_num)
  let l:line = getline(a:l_num)

  if l:line =~# '\v^\S'
    " CASE 1: non-indented lines

    if s:IsDef(l:line)
      " A function starting at column 0 opens a new fold
      return '>1'
    else
      " All other non-indented lines should be unfolded
      return '0'
    endif

  elseif s:FirstLineInClass(a:l_num) && indent(a:l_num - 1) == 0
    " CASE 2: First line of a top-level class
    return '>1'

  elseif l:line =~# '\v^\s*$'
    " CASE 3: blank lines

    if s:LastLineBeforeClass(a:l_num)
      " The last line before a class definition shares its foldlevel
      return '-1'
    else
      " All other blank lines share the foldlevel of the previous line
      return '='
    endif

  else
    " CASE 4: indented, non-blank lines which *don't* start a top-level class

    if s:IsDef(l:line) || s:FirstLineInClass(a:l_num)
      " If we start a new fold, guess its level based on the shiftwidth
      return '>'.(s:Indent(a:l_num) + (s:IsDef(l:line) ? 1 : 0))
    else
      " Most lines inherit the foldlevel of the line above
      return '='
    endif

  endif
endfunction

" SECTION: Test functions {{{1

function! foldypython#Test1()
  let l:line = s:PrevLessIndentedMatch("(class|def)", indent("."))
  echom "Line" line(".") "nests under line" l:line
  echom "Foldlevel is" foldlevel(l:line)
endfunction

function! foldypython#Test2()
  let l:not = (s:FirstLineInClass(line(".")) ? "" : " not")
  echom "Line" line(".") "is".l:not "the first line in a class"
endfunction

function! foldypython#Test3()
  echom "Fold as" foldypython#FoldLevel(line("."))
endfunction

function! foldypython#Test4()
  echom "Indent level:" s:Indent(line("."))
endfunction
