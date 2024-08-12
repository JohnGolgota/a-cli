$APaths = Join-Path $PSScriptRoot "bin" "ACliData.ps1"
$ACliPath = Join-Path $PSScriptRoot "bin" "A.ps1"

function Test-ACliDependencies
{
    if (-not(Test-Path $APaths))
    {
        Write-Host "Creando archivo $APaths"
        New-Item -Path $APaths -ErrorAction SilentlyContinue
    }
    if (-not(Test-Path $ACliPath))
    {
        Write-Host "Creando archivo $ACliPath"
        New-Item -Path $ACliPath -ErrorAction SilentlyContinue
    }
}

function Write-ACliParams
{
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$ACliObj
    )
    try
    {
        Test-ACliDependencies

        $ACliNamesObj = @()
        Set-Content -Path $APaths -Value '$ACliObj = @{'
        foreach ($Repo in $ACliObj.GetEnumerator())
        {
            Add-Content -Path $APaths -value "`"$($Repo.Key)`"=`"$($Repo.Value)`""
            # array from hashtable keys
            $ACliNamesObj += $Repo.Key
        }
        Add-Content -Path $APaths -value "}"

        $ACliNamesObjJoin = $ACliNamesObj -join "','"
        Add-Content -Path $APaths -value $('$ACliNamesObj = @(' + "'$ACliNamesObjJoin'" + ')')
    } catch
    {
        Write-Host "Error: $($_.Exception.Message)"
    }
}
function Remove-ACli
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$ToRemove
    )
    try
    {
        Test-ACliDependencies

        $ACliObj = @{}
        . $APaths
        $ACliObj.Remove($ToRemove)
        Write-ACliParams -ACliObj $ACliObj
        Build-ACli
    } catch
    {
        Write-Host "Error: $($_.Exception.Message)"
    }
}
function Add-ACli
{
    param (
        [string]$NewName = (Get-Item (Get-Location).Path).Name,

        [string]$NewPath = (Get-Location).Path
    )
    try
    {
        Test-ACliDependencies


        $ACliObj = @{}
        . $APaths
        # TODO validate if repo exists
        $ACliObj.Add($NewName, $NewPath)
        Write-ACliParams -ACliObj $ACliObj
        Build-ACli
    } catch
    {
        Write-Host "Error: $($_.Exception.Message)"
    }
}
function Get-ACli
{
    try
    {
        Test-ACliDependencies

        $ACliObj = @{}
        . $APaths
        $ACliObj.GetEnumerator()
    } catch
    {
        Write-Host "Error: $($_.Exception.Message)"
    }
}
function Edit-ACli
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$RepoToEdit,

        [Parameter()]
        [string]$NewPath,

        [Parameter()]
        [string]$NewName,

        [switch]$OnlyName = $false
    )
    try
    {
        Test-ACliDependencies

        $ACliObj = @{}
        . $APaths
        Write-Host "RepoToEdit: $RepoToEdit"


        Write-Host "Confirmación de parámetros: NewPath: $NewPath, NewName: $NewName, OnlyName: $OnlyName"
        if (-not $ACliObj.ContainsKey($RepoToEdit))
        {
            throw "El repositorio '$RepoToEdit' no existe, no se puede editar. Las opciones válidas son: $($ACliObj.Keys -join ', ')"
        }
        Write-Host "El repositorio '$RepoToEdit' existe"
        if ($NewPath -eq "" -or $null -eq $NewPath)
        {
            $NewPath = $ACliObj[$RepoToEdit]
            Write-Host "No se ha proporcionado un nuevo directorio para el repositorio, se usará el actual"
        }
        if (-not (Test-Path $NewPath))
        {
            throw "El directorio '$NewPath' no existe"
        }
        Write-Host "El directorio '$NewPath' existe"

        if ($NewName -ne "" -and $OnlyName -eq $true)
        {
            Write-Host "Se ha proporcionado un nuevo nombre para el repositorio"
            $ACliObj.Add($NewName, $ACliObj[$RepoToEdit])
            $ACliObj.Remove($RepoToEdit)
        } elseif ($NewName -ne "" -and $OnlyName -eq $false)
        {
            Write-Host "Se ha proporcionado un nuevo nombre y un nuevo directorio para el repositorio"
            $ACliObj.Remove($RepoToEdit)
            $ACliObj.Add($NewName, $NewPath)
        } else
        {
            Write-Host "Se ha proporcionado un nuevo directorio para el repositorio"
            $ACliObj[$RepoToEdit] = $NewPath
        }

        Write-ACliParams -ACliObj $ACliObj
        Build-ACli
    } catch
    {
        Write-Host "Error: $($_.Exception.Message)"
    }

}
function Build-ACli
{
    Test-ACliDependencies

    $ACliObj = @{}
    $ACliNamesObj = @()
    . $APaths
    $ACliNamesObj = $ACliNamesObj -join "','"
    Set-Content -Path $ACliPath -Value @"
    param (
        [ValidateSet('$ACliNamesObj')]
        [string]`$Repo = "NoRepoProvided"
    )
    try {
        Write-Host "Repo: `$Repo"

        `$repos = @{
"@
    foreach ($Repo in $ACliObj.GetEnumerator())
    {
        Add-Content -Path $ACliPath -Value "`"$($Repo.Key)`" = `"$($Repo.Value)`""
    }
    Add-Content -Path $ACliPath -Value @"
        }
        if (`$repos.ContainsKey(`$Repo)) {
            cd `$repos[`$Repo]
        } else {
           throw "El Repositorio `$Repo No existe."
        }
    }
    catch {
        Write-Host "Error: `$(`$_.Exception.Message)"
    }
"@
}