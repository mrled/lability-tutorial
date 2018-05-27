[CmdletBinding()] Param(
    [Array] $ErrorList = $global:Error,
    [Int] $ExitCode = $global:LASTEXITCODE,
    [switch] $ExitIfErrors,
    [Int] $WrapWidth
)

function WrapText {
    param($text, $width, $indentSpaces)
    $width = $width -1
    $indent = " " * $indentSpaces
    foreach ($line in ($text -split "`n")) {
        while ($line.length -gt $width) {
            $line = "$indent$line"
            Write-Output -InputObject $line.substring(0,$width)
            $line = $line.substring($width)
        }
        Write-Output -InputObject "$indent$line"
    }
}

if (-not $WrapWidth) {
    if ($Host.UI.RawUI.Buffersize.Width) {
        $WrapWidth = $Host.UI.RawUI.Buffersize.Width
    } else {
        $WrapWidth = 9999
    }
}

if ($ErrorList.count -or $ExitCode) {
    Write-Output -InputObject "ERROR Report: `$LASTEXITCODE=$ExitCode, `$Error.count=$($Error.count)"
    for ($i=$ErrorList.count -1; $i -ge 0; $i-=1) {
        $err = $ErrorList[$i]
        Write-Output -InputObject "`$Error[$i]:"

        # $error can contain at least 2 kind of objects - ErrorRecord objects, and things that wrap ErrorRecord objects
        # The information we need is found in the ErrorRecord objects, so unwrap them here if necessary
        if ($err.PSObject.Properties['ErrorRecord']) {$err = $err.ErrorRecord}

        WrapText -text $err.ToString() -width $WrapWidth -indentSpaces 4

        if ($err.ScriptStackTrace) {
            WrapText -text $err.ScriptStackTrace -width $WrapWidth -indentSpaces 8
        }
    }
    if ($ExitIfErrors) {
        exit 1
    }
}
else {
    Write-Output -InputObject "ERROR Report: No errors"
}
