" ====================================================
" Filename:    plugin/vtr.vim
" Description: VTR commands and variables
" Original Author: Chris Toomey
" Author:      Nick Murphy
" License:     MIT
" Last Change: 2019-12-05
" ====================================================

" Init variables
let g:VtrPercentage = get(g:, 'VtrPercentage', 20)
let g:VtrOrientation = get(g:, 'VtrOrientation', 'v')
let g:VtrInitialCommand = get(g:, 'VtrInitialCommand', '')
let g:VtrGitCdUpOnOpen = get(g:, 'VtrGitCdUpOnOpen', 0)
let g:VtrClearBeforeSend = get(g:, 'VtrClearBeforeSend', 1)
let g:VtrPrompt = get(g:, 'VtrPrompt', 'Command to run: ')
let g:VtrUseVtrMaps = get(g:, 'VtrUseVtrMaps', 0)
let g:VtrClearOnReorient = get(g:, 'VtrClearOnReorient', 1)
let g:VtrClearOnReattach = get(g:, 'VtrClearOnReattach', 1)
let g:VtrDetachedName = get(g:, 'VtrDetachedName', 'VTR_Pane')
let g:VtrClearSequence = get(g:, 'VtrClearSequence', '')
let g:VtrDisplayPaneNumbers = get(g:, 'VtrDisplayPaneNumbers', 1)
let g:VtrStripLeadingWhitespace = get(g:, 'VtrStripLeadingWhitespace', 1)
let g:VtrClearEmptyLines = get(g:, 'VtrClearEmptyLines', 1)
let g:VtrAppendNewline = get(g:, 'VtrAppendNewline', 0)

command! -bang -nargs=? VtrSendCommandToRunner call vtr#send_command_to_runner(<bang>0, <f-args>)
command! -bang -range VtrSendLinesToRunner <line1>,<line2>call vtr#send_lines_to_runner(<bang>0)
command! -bang VtrSendFile call s:SendFileViaVtr(<bang>0)
command! -nargs=? VtrOpenRunner call s:EnsureRunnerPane(<args>)
command! VtrKillRunner call s:KillRunnerPane()
command! -bang VtrFocusRunner call s:FocusRunnerPane(<bang>!0)
command! VtrReorientRunner call s:ReorientRunner()
command! VtrDetachRunner call s:DetachRunnerPane()
command! VtrReattachRunner call s:ReattachPane()
command! VtrClearRunner call s:SendClearSequence()
command! VtrFlushCommand call s:FlushCommand()
command! VtrSendCtrlD call s:SendCtrlD()
command! -bang -nargs=? -bar VtrAttachToPane call s:AttachToPane(<f-args>)

if g:VtrUseVtrMaps
    nnoremap <leader>va :VtrAttachToPane<cr>
    nnoremap <leader>ror :VtrReorientRunner<cr>
    nnoremap <leader>sc :VtrSendCommandToRunner<cr>
    nnoremap <leader>sl :VtrSendLinesToRunner<cr>
    vnoremap <leader>sl :VtrSendLinesToRunner<cr>
    nnoremap <leader>or :VtrOpenRunner<cr>
    nnoremap <leader>kr :VtrKillRunner<cr>
    nnoremap <leader>fr :VtrFocusRunner<cr>
    nnoremap <leader>dr :VtrDetachRunner<cr>
    nnoremap <leader>cr :VtrClearRunner<cr>
    nnoremap <leader>fc :VtrFlushCommand<cr>
    nnoremap <leader>sf :VtrSendFile<cr>
endif
