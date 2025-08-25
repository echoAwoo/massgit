[CmdletBinding()]
param(
    [string] $action = 'pull',
    [string] $directory = './'
)
Format-Table -InputObject $PSBoundParameters
$this = @{
    task = "git $action";
    exe  = $PSCommandPath;
    dir  = Resolve-Path -Path "$directory" -Force;
}
Format-Table -InputObject $this
$b = $PSStyle.Bold; $u = $PSStyle.Underline; $i = $PSStyle.Italic; $r = $PSStyle.Reset;
$bg = $PSStyle.Background; $fg = $PSStyle.Foreground;
$PSStyle.Formatting.Verbose = $fg.Green;
$PSStyle.Formatting.Debug = $fg.Magenta;
$PSStyle.Formatting.Error = $fg.Red;
$PSStyle.Formatting.Warning = $fg.Yellow;
$PSStyle.Formatting.FeedbackText = $fg.Gray;
$style = @{
    h1 = "$($r+$b+$u + $fg.Blue)"
    h2 = "$($r+$u + $fg.Cyan)"
    b1 = "$($r + $fg.White)"
    b2 = "$($r + $i + $fg.Black)"
};
Write-Verbose "$($style.b1)Task$r`: $($style.b2)$($this.task)$r
          $($style.b1)Dir$r`: $($style.b2)$($this.dir)$r";

$this.contents = Get-ChildItem -Path "$($this.dir)" -Force -Directory;
if ($VerbosePreference -or $DebugPreference) {
    Format-Table -InputObject $this.contents -Property Name, LastWriteTime;
}
foreach ($item in $this.contents) {
    Write-Verbose "$($style.b1)Processing directory$r`: $($style.b2)$($item.FullName)$r";
    if ($DebugPreference) {
        Write-Debug $item.FullName
    }
    if ($item.Name -eq '.git') {
        Write-Verbose "$($style.b1)Found git directory$r`: $($style.b2)$($item.FullName)$r";
        $cmd = "$($this.task) 'origin' --autostash --progress --no-recurse-submodules"
        if ($VerbosePreference) { $cmd += ' -v'; }
        $cmd += " && cd -;";
        $cmd = "`cd `"$($this.dir)`" && $cmd";
        Write-Debug $cmd
        $res = Invoke-Expression -Command $cmd 2>&1 -OutVariable $res -ErrorVariable $err -InformationVariable $info;
        foreach ($msg in @($res, $info, $err)) { Write-Output $msg | more /E; }
        continue;
    }
    $cmd = "$($this.exe) `"$action`" `"$($item.FullName)`"";
    if ($DebugPreference) { $cmd += ' -Debug'; }
    if ($VerbosePreference) { $cmd += ' -Verbose'; }
    echo "$cmd"
    Invoke-Expression -Command "$cmd" 2>&1 | more /E
}
