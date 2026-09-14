function Read-Default {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Prompt,

        [Parameter(Mandatory)]
        [object]$Default
    )

    $type = $Default.GetType()

    Write-Host "$Prompt"
    Write-Host "Default value: $Default"
    Write-Host "(Press Enter to accept the default value of '$Default')"

    Write-Verbose "Expected type: $($type.FullName)"

    $input = Read-Host ">"

    if ([string]::IsNullOrWhiteSpace($input)) {
        $value = $Default
    }
    else {
        try {
            $value = $input -as $type
            if ($null -eq $value) {
                throw "Type conversion failed"
            }
        }
        catch {
            Write-Warning "Invalid input. Using default value: $Default"
            $value = $Default
        }
    }

    Write-Host "Value set to: $value"
    return $value
}