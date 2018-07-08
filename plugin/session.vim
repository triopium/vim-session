"TODO:
"5. Rewrite bash printf to vim printf
"4. Show file names in session, list number of files in session
"3. Window frame management
"2. Default session directory as global? variable to simplify functions

"CREATE DEFAULT SESSION DIRECTORY:
function! session#DirCreate()
	"TEST FOR SYSTEM"
	try
		if has('unix')
			"Linux"
			let l:destdir=expand("~/.vim/sessions/")
			if !isdirectory(l:destdir)==1
				exe !mkdir -p expand("l:destdir")
				""echo "Created dir: ". expand(l:destdir)
			endif
				""echo "Session dir: ". expand(l:destdir)
		else 
			echoerr "Not supported on current system, default directory must be specified in code"	
		endif
	endtry
	return l:destdir
endfunction
""echo session#DirCreate()

"CREATE SESSION FILE:"
function! session#Save(...)
	let l:destdir=session#DirCreate()
	"Test optional parameters"
	if a:0 == 1 && a:1 !=? ''
		let l:fnametest=l:destdir . a:1
		if filereadable(l:fnametest)
			call inputsave()
				let l:ch=confirm("Overwrite session file:\n" . l:fnametest,"&No\n&Yes\n&Cancel")
				let l:destfile=(l:ch==2) ? l:fnametest : ''
				if l:ch==3 | echo "\nCancelled" | return 0 | endif
			call inputrestore()
		else
			let l:destfile=l:fnametest
		endif
	elseif a:0 == 0 || a:1 ==? ''
		if v:this_session==#''
			let l:destfile=''
		else
			let l:destfile=v:this_session
		endif
	else
		echoerr "Wrong number of parametters"
	endif

	"Choose filename for session file"
	call inputsave()
	while l:destfile==#''
		let l:fnametest=l:destdir . input("Enter session name: ")
		if filereadable(l:fnametest)
			call inputsave()
			let l:ch=confirm("Overwrite session file:\n" . l:fnametest ,"&No\n&Yes\n&Cancel")
			call inputrestore()
			let l:destfile=(l:ch==2) ? l:fnametest : ''
			if l:ch==3 | echo "\nCancelled" | return 0 | endif
		else
			let l:destfile=l:fnametest
		endif
	endwhile
	call inputrestore()
	exe "mks! " . l:destfile
	echo "\nSession saved to: " . l:destfile
endfunction
command! -nargs=? Mks call session#Save(<q-args>)

"DISPLAY SESSIONS IN DEFAULT DIR:
function! session#MenuList()
	let l:sessionlist=session#ListMake()
	let l:destdir=session#DirCreate()
	let l:bufname="SessionsList"
	let l:bfnr=bufwinnr(l:bufname)
	if l:bfnr > 0
	If buffer is visible, go to it clear it" 
		exe l:bfnr . "wincmd w"
		%d_
	else
	"Create scratch buffer"
		""exe 'lefta vnew' l:bufname
		exe 'sp' l:bufname
		setlocal buftype=nofile
		setlocal bufhidden=hide
		setlocal noswapfile
		setlocal nowrap
		nnoremap <buffer> q :bw<CR>
 		exe "nnoremap <buffer> <CR> :call session#Load()<CR>"
	endif
	""resize window according to table width
	let l:winwidth=array#GetMaxWidth(l:sessionlist)
	exe 'vertical res ' . l:winwidth
	silent 0put =l:sessionlist
	silent %!column -t
endfunction
""call session#MenuList()
command! Mkl call session#MenuList()

"MAKE SESSION LIST:"
function! session#ListMake()
	let l:destdir=session#DirCreate()
	"Test for system"
	""try
		if has('unix')
			let l:colnames="Name\tAccess\tChange"
			let l:format=' -printf ' . '''%f\t%AY/%Am/%Ad_%AH:%AM\t%CY/%Cm/%Cd_%CH:%CM\n'''
			let l:bashcomm="find " . l:destdir . ' -type f' . l:format . "| sort"
			let l:sessionlist=systemlist(bashcomm)
			let l:sessionlist[0]=l:colnames
		else 
			echoerr "Not supported on current system"
		endif
	""endtry
	return l:sessionlist
endfunction
""echo session#ListMake()

""LOAD SESSION FILE:
function! session#Load()
	""Save all buffers prompt
	let l:curline=getline('.')
	let l:cell=matchstr(l:curline,'^.\{-}\ze\s\{2}')
	let l:sesname=session#DirCreate() . l:cell
	if !filereadable(l:sesname)
		echo "Not readable"
	else
	let l:choice=confirm('Delete current buffers:',"&yes\n&no\n&cancel",1)
	if l:choice == 1
		wall "save all buffers"
		""Delete all buffers and open new session
		call buffer#DeleteAllOther()
		exe "so " . l:sesname
	elseif l:choice == 2
		""Append selected session files
		wall "save all buffers"
		exe "so " . l:sesname
	elseif l:choice == 3
		""Cancel all
	endif
	endif
endfunction

