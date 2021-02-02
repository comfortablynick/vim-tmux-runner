" vim: fdm=expr:
let s:vtr_percentage = g:VtrPercentage
let s:vtr_orientation = g:VtrOrientation

function s:create_runner_pane(...)
    if exists('a:1')
        let s:vtr_orientation = get(a:1, 'orientation', s:vtr_orientation)
        let s:vtr_percentage = get(a:1, 'percentage', s:vtr_percentage)
        let g:VtrInitialCommand = get(a:1, 'cmd', g:VtrInitialCommand)
    endif
    let s:vim_pane = s:active_pane_index()
    let l:cmd = join(['split-window -p', s:vtr_percentage, '-'.s:vtr_orientation])
    call s:send_tmux_command(l:cmd)
    let s:runner_pane = s:active_pane_index()
    call s:focus_vim_pane()
    if g:VtrGitCdUpOnOpen
        call s:git_cd_up()
    endif
    if !empty(g:VtrInitialCommand)
        call s:send_keys(g:VtrInitialCommand)
    endif
endfunction

function vtr#detach_runner_pane()
    if !s:valid_runner_pane_set() | return | endif
    call s:break_runner_pane_to_temp_window()
    let l:cmd = join(['rename-window -t', s:detached_window, g:VtrDetachedName])
    call s:send_tmux_command(l:cmd)
endfunction

function s:valid_runner_pane_set()
    if !exists('s:runner_pane')
        call s:echo_error('No runner pane attached.')
        return 0
    endif
    if !s:validate_runner_pane_number(s:runner_pane)
        call s:echo_error('Runner pane setting ('. s:runner_pane .') is invalid. Please reattach.')
        return 0
    endif
    return 1
endfunction

function s:detached_window_out_of_sync()
    let l:window_map = s:window_map()
    if index(keys(l:window_map), s:detached_window) == -1
        return 1
    endif
    if s:window_map()[s:detached_window] != g:VtrDetachedName
        return 1
    endif
    return 0
endfunction

function s:detached_pane_available()
    if exists('s:detached_window')
        if s:detached_window_out_of_sync()
            call s:echo_error('Detached pane out of sync. Unable to kill')
            unlet s:detached_window
            return 0
        endif
    else
        call s:echo_error('No detached runner pane.')
        return 0
    endif
    return 1
endfunction

function s:require_local_pane_or_detached()
    if !exists('s:detached_window') && !exists('s:runner_pane')
        call s:echo_error('No pane, local or detached.')
        return 0
    endif
    return 1
endfunction

function s:kill_local_runner()
    if s:valid_runner_pane_set()
        let l:targeted_cmd = s:targeted_tmux_command('kill-pane', s:runner_pane)
        call s:send_tmux_command(l:targeted_cmd)
        unlet s:runner_pane
    endif
endfunction

function s:window_map()
    let l:window_pattern = '\v(\d+): ([-_a-zA-Z]{-})[-\* ]\s.*'
    let l:window_map = {}
    for l:line in split(s:send_tmux_command('list-windows'), "\n")
        let l:dem = split(substitute(l:line, l:window_pattern, '\1:\2', ''), ':')
        let l:window_map[l:dem[0]] = l:dem[1]
    endfor
    return l:window_map
endfunction

function s:kill_detached_window()
    if !s:detached_pane_available() | return | endif
    let l:cmd = 'kill-window -t '..s:detached_window
    call s:send_tmux_command(l:cmd)
    unlet s:detached_window
endfunction

function vtr#kill_runner_pane()
    if !s:require_local_pane_or_detached() | return | endif
    if exists('s:runner_pane')
        call s:kill_local_runner()
    else
        call s:kill_detached_window()
    endif
endfunction

function s:active_pane_index()
    return str2nr(s:send_tmux_command("display-message -p \"#{pane_index}\""))
endfunction

function s:tmux_panes()
    let l:panes = s:send_tmux_command('list-panes')
    return split(l:panes, '\n')
endfunction

function s:focus_tmux_pane(pane_number)
    let targeted_cmd = s:targeted_tmux_command('select-pane', a:pane_number)
    call s:send_tmux_command(targeted_cmd)
endfunction

function s:runner_pane_dimensions()
    let panes = s:tmux_panes()
    for pane in panes
        if pane =~ '^'.s:runner_pane
            let pattern = s:runner_pane.': [\(\d\+\)x\(\d\+\)\]'
            let pane_info =  matchlist(pane, pattern)
            return {'width': pane_info[1], 'height': pane_info[2]}
        endif
    endfor
endfunction

function vtr#focus_runner_pane(should_zoom)
    if !s:valid_runner_pane_set() | return | endif
    call s:focus_tmux_pane(s:runner_pane)
    if a:should_zoom
        call s:send_tmux_command('resize-pane -Z')
    endif
endfunction

function s:strip(string)
    return substitute(a:string, '^\s*\(.\{-}\)\s*\n\?$', '\1', '')
endfunction

function s:send_tmux_command(command)
    let prefixed_command = 'tmux '.a:command
    return s:strip(system(prefixed_command))
endfunction

function s:targeted_tmux_command(command, target_pane)
    return a:command.' -t '.a:target_pane
endfunction

function s:_send_keys(keys)
    let targeted_cmd = s:targeted_tmux_command('send-keys', s:runner_pane)
    let full_command = join([targeted_cmd, a:keys])
    call s:send_tmux_command(full_command)
endfunction

function s:send_keys(keys)
    let cmd = g:VtrClearBeforeSend ? g:VtrClearSequence.a:keys : a:keys
    call s:_send_keys(cmd)
    call s:send_enter_sequence()
endfunction

function s:send_enter_sequence()
    call s:_send_keys('Enter')
endfunction

function vtr#send_clear_sequence()
    if !s:valid_runner_pane_set() | return | endif
    call s:send_tmux_copy_mode_exit()
    call s:_send_keys(g:VtrClearSequence)
endfunction

function s:send_quit_sequence()
    if !s:valid_runner_pane_set() | return | endif
    call s:_send_keys('q')
endfunction

function s:git_cd_up()
    let git_repo_check = 'git rev-parse --git-dir > /dev/null 2>&1'
    let cdup_cmd = "cd './'$(git rev-parse --show-cdup)"
    let cmd = shellescape(join([git_repo_check, '&&', cdup_cmd]))
    call s:send_tmux_copy_mode_exit()
    call s:send_keys(cmd)
    call vtr#send_clear_sequence()
endfunction

function s:focus_vim_pane()
    call s:focus_tmux_pane(s:vim_pane)
endfunction

function s:last_window_number()
    return split(s:send_tmux_command('list-windows'), '\n')[-1][0]
endfunction

function s:toggle_orientation_variable()
    let s:vtr_orientation = (s:vtr_orientation ==? 'v' ? 'h' : 'v')
endfunction

function s:break_runner_pane_to_temp_window()
    let targeted_cmd = s:targeted_tmux_command('break-pane', s:runner_pane)
    let full_command = join([targeted_cmd, '-d'])
    call s:send_tmux_command(full_command)
    let s:detached_window = s:last_window_number()
    let s:vim_pane = s:active_pane_index()
    unlet s:runner_pane
endfunction

function s:runner_dimension_spec()
    let dimensions = join(['-p', s:vtr_percentage, '-'.s:vtr_orientation])
    return dimensions
endfunction

function s:tmux_info(message)
    " TODO: this should accept optional target pane, default to current.
    " Pass that to TargetedCommand as "display-message", "-p '#{...}')
    return s:send_tmux_command("display-message -p '#{" . a:message . "}'")
endfunction

function s:pane_count()
    return str2nr(s:tmux_info('window_panes'))
endfunction

function s:pane_indicies()
    let index_slicer = 'str2nr(substitute(v:val, "\\v(\\d+):.*", "\\1", ""))'
    return map(s:tmux_panes(), index_slicer)
endfunction

function s:available_runner_pane_indices()
    return filter(s:pane_indicies(), 'v:val != '.s:active_pane_index())
endfunction

function s:alt_pane()
    if s:pane_count() == 2
        return s:available_runner_pane_indices()[0]
    else
        echoerr 'AltPane only valid if two panes open'
    endif
endfunction

function vtr#attach_to_pane(...)
    if !empty(get(a:, 1, ''))
        call s:attach_to_specified_pane(a:1)
    elseif s:pane_count() == 2
        call s:attach_to_specified_pane(s:alt_pane())
    else
        call s:prompt_for_pane_to_attach()
    endif
endfunction

function s:prompt_for_pane_to_attach()
    if g:VtrDisplayPaneNumbers
        call s:send_tmux_command('source ~/.tmux.conf && tmux display-panes')
    endif
    echohl String | let desired_pane = input('Pane #: ') | echohl None
    if !empty('desired_pane')
        call s:attach_to_specified_pane(desired_pane)
    else
        call s:echo_error('No pane specified. Cancelling.')
    endif
endfunction

function s:current_major_orientation()
    let orientation_map = { '[': 'v', '{': 'h' }
    let layout = s:tmux_info('window_layout')
    let outermost_orientation = substitute(layout, '[^[{]', '', 'g')[0]
    return orientation_map[outermost_orientation]
endfunction

function s:attach_to_specified_pane(desired_pane)
    let desired_pane = str2nr(a:desired_pane)
    if s:validate_runner_pane_number(desired_pane)
        let s:runner_pane = desired_pane
        let s:vim_pane = s:active_pane_index()
        let s:vtr_orientation = s:current_major_orientation()
        echohl String | echo "\rRunner pane set to: " . desired_pane | echohl None
    else
        call s:echo_error('Invalid pane number: ' . desired_pane)
    endif
endfunction

function s:echo_error(message)
    echohl ErrorMsg | echo "\rVTR: ". a:message | echohl None
endfunction

function s:desired_pane_exists(desired_pane)
    return count(s:pane_indicies(), a:desired_pane) == 0
endfunction

function s:validate_runner_pane_number(desired_pane)
    if a:desired_pane == s:active_pane_index() | return 0 | endif
    if s:desired_pane_exists(a:desired_pane) | return 0 | endif
    return 1
endfunction

function vtr#reattach_pane()
    if !s:detached_pane_available() | return | endif
    let s:vim_pane = s:active_pane_index()
    call s:reattach_pane()
    call s:focus_vim_pane()
    if g:VtrClearOnReattach
        call vtr#send_clear_sequence()
    endif
endfunction

function s:reattach_pane()
    let join_cmd = join(['join-pane', '-s', ':'.s:detached_window.'.0',
        \ s:runner_dimension_spec()])
    call s:send_tmux_command(join_cmd)
    unlet s:detached_window
    let s:runner_pane = s:active_pane_index()
endfunction

function vtr#reorient_runner()
    if !s:valid_runner_pane_set() | return | endif
    call s:break_runner_pane_to_temp_window()
    call s:toggle_orientation_variable()
    call s:reattach_pane()
    call s:focus_vim_pane()
    if g:VtrClearOnReorient
        call vtr#send_clear_sequence()
    endif
endfunction

function s:highlighted_prompt(prompt)
    echohl String | let input = shellescape(input(a:prompt)) | echohl None
    return input
endfunction

function vtr#flush_command()
    if exists('s:user_command')
        unlet s:user_command
    endif
endfunction

function s:send_tmux_copy_mode_exit()
    let l:session = s:tmux_info('session_name')
    let l:win = s:tmux_info('window_index')
    let target_cmd = join([l:session.':'.l:win.'.'.s:runner_pane])
    if s:send_tmux_command("display-message -p -F '#{pane_in_mode}' -t " . l:target_cmd)
        call s:send_quit_sequence()
    endif
endfunction

function vtr#send_command_to_runner(ensure_pane, ...)
    if a:ensure_pane | call vtr#ensure_runner_pane() | endif
    if !s:valid_runner_pane_set() | return | endif
    if !empty(get(a:, 1, ''))
        let s:user_command = shellescape(a:1)
    endif
    if empty('s:user_command')
        let s:user_command = s:highlighted_prompt(g:VtrPrompt)
    endif
    let escaped_empty_string = "''"
    if s:user_command == escaped_empty_string
        unlet s:user_command
        call s:echo_error('command string required')
        return
    endif
    call s:send_tmux_copy_mode_exit()
    if g:VtrClearBeforeSend
        call vtr#send_clear_sequence()
    endif
    call s:send_keys(s:user_command)
endfunction

function vtr#ensure_runner_pane(...)
    if exists('s:detached_window')
        call vtr#reattach_pane()
    elseif exists('s:runner_pane')
        return
    else
        if exists('a:1')
            call s:create_runner_pane(a:1)
        else
            call s:create_runner_pane()
        endif
    endif
endfunction

function vtr#send_lines_to_runner(ensure_pane) range
    if a:ensure_pane | call vtr#ensure_runner_pane() | endif
    if !s:valid_runner_pane_set() | return | endif
    call s:send_tmux_copy_mode_exit()
    call s:send_text_to_runner(getline(a:firstline, a:lastline))
endfunction

function s:prepare_lines(lines)
    let prepared = a:lines
    if g:VtrStripLeadingWhitespace
        let prepared = map(a:lines, 'substitute(v:val,"^\\s*","","")')
    endif
    if g:VtrClearEmptyLines
        let prepared = filter(prepared, '!empty(v:val)')
    endif
    if g:VtrAppendNewline && len(a:lines) > 1
        let prepared = add(prepared, "\r")
    endif
    return prepared
endfunction

function s:send_text_to_runner(lines)
    if !s:valid_runner_pane_set() | return | endif
    let prepared = s:prepare_lines(a:lines)
    let joined_lines = join(prepared, "\r") . "\r"
    let send_keys_cmd = s:targeted_tmux_command('send-keys', s:runner_pane)
    let targeted_cmd = send_keys_cmd . ' ' . shellescape(joined_lines)
    call s:send_tmux_command(targeted_cmd)
endfunction

function vtr#send_ctrl_id()
    if !s:valid_runner_pane_set() | return | endif
    call s:send_tmux_copy_mode_exit()
    call s:send_keys('')
endfunction

function vtr#send_file_via_vtr(ensure_pane)
    let runners = s:current_filetype_runners()
    if has_key(runners, &filetype)
        write
        let runner = runners[&filetype]
        let local_file_path = expand('%')
        let run_command = substitute(runner, '{file}', local_file_path, 'g')
        call s:vtr_send_command(run_command, a:ensure_pane)
    else
        echoerr 'Unable to determine runner'
    endif
endfunction

function s:current_filetype_runners()
    let default_runners = {
        \ 'elixir': 'elixir {file}',
        \ 'javascript': 'node {file}',
        \ 'python': 'python {file}',
        \ 'ruby': 'ruby {file}',
        \ 'sh': 'sh {file}'
        \ }
    if exists('g:vtr_filetype_runner_overrides')
        return extend(copy(default_runners), g:vtr_filetype_runner_overrides)
    else
        return default_runners
    endif
endfunction

function s:vtr_send_command(command, ...)
    let ensure_pane = get(a:, 1, 0)
    call vtr#send_command_to_runner(ensure_pane, a:command)
endfunction
