"if exists("g:loaded_vkg")
	"finish
"endif
"let g:loaded_vkg=0.1

" vkg helper functions ---------------------------------------------- {{{

fun! s:VkgCleanSearchOutput( output ) "{{{
	let clean_output = []

	for line in a:output
		call add(clean_output, substitute( substitute(line, '[32m', '', 'g'), '[39m', '', 'g'))
	endfor

	return clean_output
endfun "}}}

fun! s:VkgSettings() "{{{
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal nobuflisted
	setlocal filetype=vkg
	setlocal nolist
	setlocal nonumber
	setlocal norelativenumber
	setlocal nowrap

	call s:VkgSyntax()
	call s:VkgMappings()
endfun "}}}

fun! s:VkgSyntax() "{{{
	syn match VkgStar '*'
	syn match VkgPluginName '\* ([0-9A-Za-z\-]+) \-'

	hi def link VkgStar Keyword
	hi def link VkgPluginName Identifier
endfun "}}}

fun! s:VkgMappings() "{{{
	nnoremap <script> <silent> <buffer> <CR> :call <sid>VkgInstallCurrent()<CR>
	nnoremap <script> <silent> <buffer> q execute ":q!"
endfun "}}}

fun! s:VkgInstallCurrent() "{{{
	let line_parts = split(getline("."))

	call vkg#install(line_parts[1])
endfun "}}}

" }}}

" vkg cli functions ------------------------------------------------- {{{

fun! vkg#install( name ) "{{{
	let response = input("Do you want to install " . a:name . "? y|n ")

	if response == 'y'
		let output = system("vkg install " . a:name)
		echo output
	endif
endfun "}}}

fun! vkg#uninstall( name ) "{{{
	let output = system("vkg uninstall " . a:name)
	echo output
endfun "}}}

fun! vkg#search( name ) "{{{
	let command_output = system( "vkg search " . a:name)
	if command_output == ''
		echo "No plugins match " . a:name
	else
		let lines = split( command_output, '\n' )
		let clean_output = s:VkgCleanSearchOutput( lines )
		call s:VkgRender( clean_output )
	endif
endfun "}}}

fun! vkg#list() "{{{
	let command_output = system( "vkg list" )
	let lines = split( command_output, '\n' )
	let clean_output = s:VkgCleanSearchOutput( lines )
	call s:VkgRender( clean_output )
endfun "}}}

fun! vkg#dispatch( ... ) "{{{
	if a:0 == 0
		echo "Invalid parameter number."
		\"\nUsage:\n" .
		\"  :Vkg search <plugin>\n"
		\" :Vkg install <plugin>\n"
		\" :Vkg uninstall <plugin>\n"
		\" :Vkg list\n"
	elseif a:1 == "search"
		call vkg#search(a:2)
	elseif a:1 == "install"
		call vkg#install(a:2)
	elseif a:1 == "uninstall"
		call vkg#uninstall(a:2)
	elseif a:1 == "list"
		call vkg#list()
	endif
endfun "}}}

"}}}

" UI functions ------------------------------------------------------ {{{

fun! s:VkgOpenBuffer() " {{{
	let existing_vkg_buffer = bufnr("__Vkg__")
	if existing_vkg_buffer == -1
		exec "botright new __Vkg__"
	else
		let existing_vkg_window = bufwinnr(existing_vkg_buffer)
		if existing_vkg_window != -1
			if winnr() != existing_vkg_window
				exe existing_vkg_window . "wincmd w"
			endif
		else
			exe "botright split +buffer" . existing_vkg_buffer
		endif
	endif
	call s:VkgResizeBuffer(winnr())
endfun "}}}

fun! s:VkgIsVisible() "{{{
	if bufwinnr(bufnr("__Vkg__")) != -1
		return 1
	else
		return 0
	endif
endfun "}}}

fun! s:VkgGoToWindow() "{{{
	if bufwinnr(bufnr("__Vkg__")) != -1
		exe bufwinnr(bufnr("__Vkg__")) . "wincmd w"
		return 1
	else
		return 0
	endif
endfun "}}}

fun! s:VkgResizeBuffer( backto ) "{{{
	call s:VkgGoToWindow()
	exe "resize 15"

	exe a:backto . "wincmd w"
endfun "}}}

fun! s:VkgRender( lines ) "{{{
	call s:VkgOpenBuffer()
	call s:VkgGoToWindow()
	call s:VkgCleanBuffer()
	setlocal modifiable
	for line in a:lines
		call s:VkgPutLineInBuffer( line )
	endfor
	normal! ggdd
	setlocal nomodifiable
endfun "}}}

fun! s:VkgPutLineInBuffer( line ) " {{{
	let @a = a:line
	normal! G
	execute "put a"
endfun "}}}

fun! s:VkgCleanBuffer() "{{{
	set modifiable
	normal! ggVGd
	set nomodifiable
endfun "}}}

" }}}

command! -nargs=* Vkg call vkg#dispatch(<f-args>)

augroup VkgAug
	autocmd!
	autocmd BufNewFile __Vkg__ call s:VkgSettings()
augroup END
