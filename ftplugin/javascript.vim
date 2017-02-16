"" @see http://stackoverflow.com/questions/18807349/a-reduce-function-in-vim-script
fun! s:Reduce(funcref, list, acc)
    let acc = a:acc
    for value in a:list[:]
        let acc = function(a:funcref, [acc, value])()
    endfor
    return acc
endfun

fun! s:GetNodeModulesAbsPath ()
  let lcd_saved = fnameescape(getcwd())
  silent! exec "lcd" expand('%:p:h')
  let path = finddir('node_modules', '.;')
  exec "lcd" lcd_saved

  return path is '' ? v:null : fnamemodify(path, ':p')
endfun

" syntastic_checker[]
" -> s:DescribeLocalChecker(acc_dict, checker)
" -> {'eslint': s:GetLocalBin('eslint'), 'flow': s:GetLocalBin('flow')}
" -> for checker in dict do SetChecker(checker, dict.checker)

fun! s:GetLocalBin (node_modules_path, checker)
  let checker_bin =  a:node_modules_path . '/.bin/' . a:checker
  return executable(checker_bin) ? checker_bin : v:null
endfun

fun! s:DescribeLocalChecker (node_modules, acc, checker)
  let acc = a:acc
  let checker_bin = s:GetLocalBin(a:node_modules, a:checker)
  let acc[a:checker] = checker_bin
  return acc
endfun

fun! s:SetCheckers (checkers, politeness)
  for [name, bin] in items(a:checkers)
    if bin is v:null
      let message = 'Syntastic local javascript checkers: no local ' . name . ' found'
      call s:Echo(a:politeness, message)
    else
      exec 'let b:syntastic_javascript_' . name . '_exec = "' . bin . '"'
    endif
  endfor
endfun

" Delivery the message to the user
"
" politeness is a number: 0, 1, or 2.
" When 'node_modules' no local executable for a checker was found, the plugin will inform
" the user about that. How this is done depends on the [politeness] setting:
" 2: be silent, don't show any messages
" 1: echo message 'Syntastic local javascript checker: no local {checker} found'
" 0: echoerr the same message
" Default politeness is 2
" NOTE: when node_modules not found at all, then there is no errors
fun! s:Echo (politeness, message)
  if a:politeness =~ 2
    return
  elseif a:politeness =~ 1
    echo a:message
    return
  elseif a:politeness =~ 0
    echoerr a:message
    return
  else
    echoerr 'g:syntastic_local_javascript_checkers_politeness should be 0, 1, or 2'
  endif
endfun

fun! s:Main ()
  let politeness = get(g:, 'syntastic_local_javascript_checkers_politeness', 2)
  let checker_names = get(g:, 'syntastic_javascript_checkers', [])
  let node_modules = s:GetNodeModulesAbsPath()

  if node_modules is v:null " we're outside of any js project
    return
  else
    let s:LocalChecker = function('s:DescribeLocalChecker', [node_modules])
    let checkers = s:Reduce(s:LocalChecker, checker_names, {})
    call s:SetCheckers(checkers, politeness)
  endif
endfun

call s:Main()
