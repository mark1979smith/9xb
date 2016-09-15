# 9xb
## .git-command.sh
### Setup Alias
```
alias g="~/bin/.git-command.sh"
```
Add the following in ~/bin/.bashrc
```
complete -o bashdefault -o default -o nospace -F _git g 2>/dev/null \
    || complete -o default -o nospace -F _git g
```
