" ====================================================
" Filename:    plugin/vtr.vim
" Description: VTR commands and variables
" Original Author: Chris Toomey
" Author:      Nick Murphy
" License:     MIT
" Last Change: 2019-12-05
" ====================================================
if exists('g:loaded_vtr') | finish | endif
let g:loaded_vtr = 1

augroup vim_tmux_runner 
    autocmd!
    autocmd QuitPre * call vtr#kill_runner_pane()
augroup END

" Init variables
let g:VtrPercentage             = get(g:, 'VtrPercentage', 20)
let g:VtrOrientation            = get(g:, 'VtrOrientation', 'v')
let g:VtrInitialCommand         = get(g:, 'VtrInitialCommand', '')
let g:VtrGitCdUpOnOpen          = get(g:, 'VtrGitCdUpOnOpen', 0)
let g:VtrClearBeforeSend        = get(g:, 'VtrClearBeforeSend', 1)
let g:VtrPrompt                 = get(g:, 'VtrPrompt', 'Command to run: ')
let g:VtrClearOnReorient        = get(g:, 'VtrClearOnReorient', 1)
let g:VtrClearOnReattach        = get(g:, 'VtrClearOnReattach', 1)
let g:VtrDetachedName           = get(g:, 'VtrDetachedName', 'VTR_Pane')
let g:VtrClearSequence          = get(g:, 'VtrClearSequence', '')
let g:VtrDisplayPaneNumbers     = get(g:, 'VtrDisplayPaneNumbers', 1)
let g:VtrStripLeadingWhitespace = get(g:, 'VtrStripLeadingWhitespace', 1)
let g:VtrClearEmptyLines        = get(g:, 'VtrClearEmptyLines', 1)
let g:VtrAppendNewline          = get(g:, 'VtrAppendNewline', 0)

command -bang -nargs=?      VtrSendCommandToRunner               call vtr#send_command_to_runner(<bang>0, <f-args>)
command -bang -range        VtrSendLinesToRunner <line1>,<line2> call vtr#send_lines_to_runner(<bang>0)
command -bang               VtrSendFile                          call vtr#send_file_via_vtr(<bang>0)
command -nargs=?            VtrOpenRunner                        call vtr#ensure_runner_pane(<args>)
command                     VtrKillRunner                        call vtr#kill_runner_pane()
command -bang               VtrFocusRunner                       call vtr#focus_runner_pane(<bang>!0)
command                     VtrReorientRunner                    call vtr#reorient_runner()
command                     VtrDetachRunner                      call vtr#detach_runner_pane()
command                     VtrReattachRunner                    call vtr#reattach_pane()
command                     VtrClearRunner                       call vtr#send_clear_sequence()
command                     VtrFlushCommand                      call vtr#flush_command()
command                     VtrSendCtrlD                         call vtr#send_ctrl_id()
command -bang -nargs=? -bar VtrAttachToPane                      call vtr#attach_to_pane(<f-args>)

nnoremap <Plug>(VtrAttachToPane)        <Cmd>VtrAttachToPane<CR>
nnoremap <Plug>(VtrReorientRunner)      <Cmd>VtrReorientRunner<CR>
nnoremap <Plug>(VtrSendCommandToRunner) <Cmd>VtrSendCommandToRunner<CR>
nnoremap <Plug>(VtrSendLinesToRunner)   <Cmd><line1>,<line2>call vtr#send_lines_to_runner()<CR>
vnoremap <Plug>(VtrSendLinesToRunner)   <Cmd>VtrSendLinesToRunner<CR>
nnoremap <Plug>(VtrSendFile)            <Cmd>VtrSendFile<CR>
nnoremap <Plug>(VtrOpenRunner)          <Cmd>VtrOpenRunner<CR>
nnoremap <Plug>(VtrKillRunner)          <Cmd>call vtr#kill_runner_pane()<CR>
nnoremap <Plug>(VtrFocusRunner)         <Cmd>VtrFocusRunner<CR>
nnoremap <Plug>(VtrDetachRunner)        <Cmd>VtrDetachRunner<CR>
nnoremap <Plug>(VtrClearRunner)         <Cmd>VtrClearRunner<CR>
nnoremap <Plug>(VtrFlushCommand)        <Cmd>VtrFlushCommand<CR>
