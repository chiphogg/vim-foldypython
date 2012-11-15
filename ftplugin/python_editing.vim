" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
finish
endif
let b:did_ftplugin = 1

"map <buffer> <S-e> :w<CR>:!/usr/bin/env python % <CR>
"map <buffer> gd /def <C-R><C-W><CR>

set foldmethod=expr
set foldexpr=foldypython#FoldLevel(v:lnum)
set foldtext=PythonFoldText()

" Utility functions {{{1

function! PythonFoldText()

    let size = printf("%4d", 1 + v:foldend - v:foldstart)

    if match(getline(v:foldstart), '"""') >= 0
        let text = substitute(getline(v:foldstart), '"""', '', 'g' ) . ' '
    elseif match(getline(v:foldstart), "'''") >= 0
        let text = substitute(getline(v:foldstart), "'''", '', 'g' ) . ' '
    else
        let text = getline(v:foldstart)
    endif

    return size . ' lines:'. text . ' '

endfunction

" FUNCTION: s:FoldlevelFromIndent(lnum) {{{2
" Determine the foldlevel associated with an indent.
" Encapsulating within a function gives flexibility to add 'smartness' later,
" i.e., to detect the style of a particular python file dynamically. 
"
" Args:
" lnum: The line number to examine
"
" Return:
" The number of indents for the given line
function! s:FoldlevelFromIndent(lnum)
    return indent(a:lnum) / &shiftwidth
endfunction

function! PythonFoldExpr(lnum)
    let l:blank = '\v^\s*$'

    " 'Class name' lines go outside the fold; preceding whitespace is unfolded
    let l:class_line =  '\v^\s*class\s'
    if getline(a:lnum + 1) =~# l:class_line
        return s:FoldlevelFromIndent(a:lnum + 1)
    elseif getline(a:lnum) =~# l:class_line
        return s:FoldlevelFromIndent(a:lnum)
    elseif getline(a:lnum - 1) =~# l:class_line
        return s:FoldlevelFromIndent(a:lnum)
    endif

    " Function definitions get included in the fold
    let l:def_line = '\v^\s*def\s'
    if getline(a:lnum) =~# l:def_line
        return ">" . (s:FoldlevelFromIndent(a:lnum) + 1)
    endif

    " Logic for blank lines:
    " If they directly precede a 'class' line, they aren't folded
    " (This logic is handled above in the 'class name' section.)
    if getline(a:lnum) =~# l:blank
"        " If the next line is NONblank, and its indent has decreased by 2 or
"        " more, unfold this line (as a visual spacer).
"        if getline(a:lnum + 1) !~# l:blank
"            let l:last_indent = s:FoldlevelFromIndent(prevnonblank(a:lnum))
"            let l:this_indent = s:FoldlevelFromIndent(a:lnum)
"            if l:this_indent < l:last_indent - 1
"                return (l:this_indent > 0) ? (l:this_indent) : 0
"            endif
"        endif
"
"        " Otherwise, fold blank lines into the preceding fold structure.
        return "="
    endif

    return '='

endfunction

" Testing
nnoremap <silent> <buffer> ,`1 :call foldypython#Test1()<CR>
nnoremap <silent> <buffer> ,`2 :call foldypython#Test2()<CR>
nnoremap <silent> <buffer> ,`3 :call foldypython#Test3()<CR>
nnoremap <silent> <buffer> ,`4 :call foldypython#Test4()<CR>
