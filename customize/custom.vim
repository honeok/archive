syntax on " 启用语法高亮

" 设置文件类型缩进
function! SetIndentForFiletype()
    if &filetype ==# 'yaml'
        setlocal tabstop=2 shiftwidth=2 expandtab
    elseif &filetype ==# 'sh'
        setlocal tabstop=4 shiftwidth=4 expandtab
    endif
endfunction

" 清理行尾空格
function! TrimWhitespace()
    let l:save = winsaveview()
    %s/\s\+$//e
    call winrestview(l:save)
endfunction

" 自动命令
augroup custom_settings
    autocmd!
    autocmd FileType yaml,sh call SetIndentForFiletype()
    autocmd BufWritePre * call TrimWhitespace()
augroup END

filetype plugin indent on " 文件类型检测
