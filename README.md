# why?

Supuesta intalacion:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri "https://raw.githubusercontent.com/JohnGolgota/a-cli/refs/heads/master/download.ps1" | Invoke-Expression
```

## install

```powershell
~/a-cli/install.ps1
. $PROFILE
```

```powershell
Test-ACliDependencies
```
