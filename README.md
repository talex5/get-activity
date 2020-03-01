An experimental script to collect your recent activity from e.g. GitHub and format it as markdown.
The idea is that you keep a journal (e.g. `log.md`) and instead of manually copying and pasting things
into it, you just run a command in your text editor and it pastes in everything you did since the last
paste. You can then edit this text as required.

For example, after creating this repository and making a PR against it, I press F5 in Vim and it inserts:

```
Created repository [talex5/get-activity](https://github.com/talex5/get-activity).

Better output for zero or one repositories [#1](https://github.com/talex5/get-activity/pull/1).  
If there is no activity, display a suitable message. If only one repository
has activity, don't add a heading for it.
```

This renders as:

> Created repository [talex5/get-activity](https://github.com/talex5/get-activity).
> 
> Better output for zero or one repositories [#1](https://github.com/talex5/get-activity/pull/1).  
> If there is no activity, display a suitable message. If only one repository
> has activity, don't add a heading for it.

## Activity sources

At the moment, GitHub activity is the only source it queries.

### GitHub

1. Go to <https://github.com/settings/tokens> and generate a new token.
   It only needs read access; I selected `public_repo, read:discussion, read:org, read:user`.

2. Save the generated token as `~/.github/github-activity-token`.

## Editors

### Vim

Put this in your `~/.vimrc`:

```
au BufRead,BufNewFile **/log.md noremap <F5> Go<Esc>:r! get-activity<CR>
au BufRead,BufNewFile **/log.md inoremap <F5> <C-O>:r! get-activity<CR>
```

Then, pressing F5 will paste recent activity.
In normal mode, it pastes it at the end of the file.
In insert mode, it pastes it at the cursor.

Tip: if you want to be able to open the URLs it adds in a browser, you can use something like this:

```vim
" gx to open URLs in Firefox
let g:netrw_browsex_viewer= "firefox"
```
