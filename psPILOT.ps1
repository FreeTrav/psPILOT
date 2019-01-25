param ( [Parameter(Mandatory=$true)][string]$sourcefile )

# Global variables

$sourcecode = Get-Content -Path $sourcefile

$program = @()

$variables = @{}

$variables["%answer"] = ""

$variables["%matched"] = $false

$variables["%uselevel"] = 0

$variables["%eof"] = $false

$printwidth = 75

$labels = @{}

$retloc = @()

$condition = $false

$prevcmd = ""

$files = @()

$atread = -1

$atwrite = -1

$ataccept = -1

# Support functions

function expandvariables {
# expands variables in a source line
    param ( [string]$line, [switch]$quoted )

    if ($quoted) {
        $line = [regex]::Replace($line,'(?<=(?<!\\)(?:\\{2})*)\$\w{1,10}\b', {param($match) $('"'+$script:variables[$match.Value]+'"') })
        $line = [regex]::Replace($line,'(?<=(?<!\\)(?:\\{2})*)#\w{1,10}\b', {param($match) $script:variables[$match.Value] })
        $line = [regex]::Replace($line,'(?<=(?<!\\)(?:\\{2})*)\%\w{1,10}\b', {param($match) if ($script:variables[$match.Value] -is [int]){ $script:variables[$match.Value] } else { $('"'+$script:variables[$match.Value]+'"') }})
    } else {
        $line = [regex]::Replace($line,'(?<=(?<!\\)(?:\\{2})*)[\%$#]\w{1,10}\b', {param($match) $script:variables[$match.Value] })
    }
    $line = [regex]::Replace($line,'\\\\',[string]0x1b)
    $line = [regex]::Replace($line,'\\','')
    $line = [regex]::Replace($line,[string]0x1b,'\')
    $line
}

function pilottype {
# implements the T: command
    param ( [string]$textline,
            [int]$width
          )

    $text = (expandvariables -line $textline.trim())
    $retval = @()
    while ($text.Length -gt $width) {
        $lastspace = $text.substring(0,$width).LastIndexOf(' ')
        $retval += ,($text.substring(0,$lastspace))
        $text = $text.substring($lastspace+1,$text.Length-($lastspace+1))
    }
    $retval += $text
    $retval
}

function pilotaccept {
#implements the A: command
    param ( [string]$acceptvar )

    $script:variables["%answer"] = Read-Host
    $script:variables[$acceptvar] = $script:variables["%answer"]
}

function pilotmatch {
#implements the M: command
    param ( [string]$matchvalue )

    $matchvalue = $matchvalue = [regex]::Replace($matchvalue,'(?<=(?<!\\)(?:\\{2})*)[\,\!]', '|')
    $temp = ($script:variables["%answer"] | Select-String -Pattern $matchvalue).Matches
    $script:variables["%matched"] = $temp.Success
    $script:variables["%match"] = $temp.Value
    $script:variables["%satisfied"] = $script:variables["%matched"]
    $scratch = $script:variables["%answer"] -split $temp.Value,2
    $script:variables["%left"] = $scratch[0]
    $script:variables["%right"] = $scratch[1]
}

function pilotcondition {
    param ( [string]$cond )

    if ($cond.Length -ne 1) {
        $iscond = ($cond | Select-String -Pattern "\(|Y|N|E").Matches
        if ($iscond.Success) {
            switch ($iscond.Value) {
                '(' {
                    $temp = $cond.Replace("<>"," -ne ").Replace("<="," -le ").Replace(">="," -ge ").Replace("<"," -lt ").Replace(">"," -gt ").Replace("="," -eq ")
                    $temp = $temp.Replace("&&"," -and ").Replace("||", " -or ").Replace("!!"," -not ")
                    $temp = Out-String -InputObject (expandvariables -line $temp -quoted).substring($iscond.Index)
                    $script:variables["%satisfied"] = Invoke-Expression -Command $temp
                    break
                }
                'Y' {
                    $script:variables["%satisfied"] = $false
                    if ($script:variables["%matched"]) { $script:variables["%satisfied"] = $true; break}
                }
                'N' {
                    $script:variables["%satisfied"] = $false
                    if (-not $script:variables["%matched"]) { $script:variables["%satisfied"] = $true; break }
                }
                'E' {
                    $script:variables["%satisfied"] = $false
                    if ($script:variables["%eof"]) { $script:variables["%satisfied"] = $true; break }
                }
                default {$script:variables["%satisfied"] = $false }
            }
        } else {
            $script:variables["%satisfied"] = $true
        }
    } else {
        $script:variables["%satisfied"] = $true
    }
    $script:variables["%satisfied"]
}

function pilotcompute {
    param( [string]$expr )

    if ($expr[0] -eq "$") {
        $varname, $varval = ($expr -split "=").trim()
        $script:variables[$varname] = expandvariables -line $varval
    } elseif ($expr[0] -eq "#") {
        $varname, $varval = ($expr -split "=").trim()
        [int]$script:variables[$varname] = [Math]::Round((Invoke-Expression -Command (expandvariables -line $varval)))
    }
}

function pilotwait {
    param( [string]$seconds )

    Start-Sleep -Seconds (expandvariables -line $seconds)
}

function loadsource {
    param( [string[]]$sourcecode )

    $localprog = @()
    $locallabels = @{}
    foreach ($line in $sourcecode) {
        $code = ($line -split "//")[0].trim()  # remove end-of-line comments and any leading or trailing white space
        $localprog += ,($code -split ":",2)
        if ($code[0] -eq "*") {
            $locallabels[$code] = $localprog.Length - 1
        }
    }
    $localprog += ,("E:" -split ":",2)
    $script:program = $localprog
    $script:labels = $locallabels
    $script:variables = @{}
    $script:variables["%answer"] = ""
    $script:variables["%matches"] = $false
    $script:variables["%uselevel"] = 0
    $script:retloc = @()
    $script:condition = $false
    $script:prevcmd = ""
    $script:IP = 0
}

function pilotsetparams {
    param ( [string]$paramline )

    if ($paramline -match "\bw(?<width>\d+)\b") {
        $script:printwidth = 0 + $matches['width']
    }
}

function pilotfilecommand {
    param ( [string]$subcommand,
            [string]$inputline )

    $handlevar,$filecommand = $inputline -split ",",2
    switch ($subcommand) {
        "A" { $script:variables[$handlevar] = $script:files.Length                              # Open - New File or Append
              $temp = New-Object -TypeName System.IO.StreamWriter($filecommand.trim(),$true)
              $script:files += ,($temp)
              break
        }
        "B" { $script:variables[$handlevar] = $script:files.Length                              # Open - Blank for writing (overwrite or new)
              $temp = New-Object -TypeName System.IO.StreamWriter($filecommand.trim(),$false)
              $script:files += ,($temp)
              break
        }
        "C" { [void]$script:files[$script:variables[$handlevar]].Close(); break }               # Close
        "D" { Remove-Item (expandvariables -line $handlevar) }
        "O" { $script:variables[$handlevar] = $script:files.Length                              # Open for Read
              $temp = New-Object -TypeName System.IO.StreamReader($filecommand.trim())
              $script:files += ,($temp)
              break
        }
        "R" { if (!$script:files[$script:variables[$handlevar]].EndOfStream) {                    # Read a line of text
                  $script:variables[$filecommand.trim()] = $script:files[$script:variables[$handlevar]].ReadLine()
                  $script:variables["%eof"] = $false
            } else { $script:variables["%eof"] = $true 
            }
            $script:atread = $script:IP
            break
        }
        "W" { $script:files[$script:variables[$handlevar]].WriteLine((expandvariables -line $filecommand)); $script:atwrite = $script:IP; $break} # Write a line of text
        default { "Unimplemented file command F$subcommand encountered"; return }
    }
}



# Main code

loadsource -sourcecode $sourcecode

$IP = 0
while ($IP -lt $program.length)  {
    $line = $program[$IP]
    if ($line.Length -gt 1) {
        if ($line[0].Length -eq 0) { $line[0] = $prevcmd } else { $prevcmd = $line[0][0] }
        if (pilotcondition -cond $line[0]) {
            switch ($line[0][0]) {
                "A" { pilotaccept -acceptvar $line[1].trim()                 # Accept - take user input from the default input stream
                  $ataccept = $IP
                  $IP++
                  break
                }
                "C" { pilotcompute -expr $line[1].trim()
                      $IP++
                }
                "E" { if ($script:variables["%uselevel"] -eq 0) {                                   # End    - Terminate program or return from subroutine
                      $IP++
                      return
                  } else { 
                      $script:variables["%uselevel"]-- 
                      $IP = $retloc[$script:variables["%uselevel"]] 
                      break
                  } 
                }
                "F" { pilotfilecommand -subcommand $line[0][1] -inputline $line[1].trim()
                      $IP++
                      break
                }
                "G" { "psPILOT does not support graphics"
                      $IP++
                      break
                }
                "J" { if (($line[1].trim())[0] -eq "@") {                        #Jump
                          switch (($line[1].trim())[1]) {
                              "A" { $IP = $ataccept        #      To the previous A:
                                    break
                              }
                              "M" { while ($program[$IP++][0] -ne "M") {}        #      To the next M:
                                    $IP--
                                    break
                              }
                              "P" { while ($program[$IP++][0] -ne "P") {}        #      To the next P:
                                    $IP--
                                    break
                              }
                              "R" { $IP = $atread        #      To the previous FR:
                                    break
                              }
                              "W" { $IP = $atwrite        #      To the previous FW:
                                    break
                              }
                          }
                      } else {                                                   #      To the specified label
                          if (($line[1].trim())[0] -ne "*") { $line[1] = "*$($line[1].trim())" }  # if it doesn't start with a *, add one
                          $dest = $labels[$line[1].Trim()]
                          if ($dest -eq $null) { "J: Undefined Label $($line[1].trim()) in line $IP" ; return } 
                          $IP = $dest
                      }
                      break
                }
                "L" { $codebuffer = Get-Content $line[1].Trim()
                      loadsource -sourcecode $codebuffer
                      break
                }
                "M" { pilotmatch -matchvalue $line[1].trim()                 # Match  - Did the last input contain the requested string as a word?
                      $IP++
                      break
                }
                "N" { if (-not $script:variables["%matched"]) {                                   # No     - Type if the last M (match) resulted in no match
                          if ($line[0] -match "H") {
                              $out = (pilottype -textline $line[1] -width $printwidth)
                              $out[0..$out.length-2] | Write-Host
                              $out[-1] | Write-Host -NoNewline
                          } else {
                              (pilottype -textline $line[1] -width $printwidth) | Write-Host
                          }
                      }
                      $IP++
                      break
                }
                "P" { pilotsetparams -paramline $line[1]                     # Problem - allows J:@P, set print width ("Wnn")
                      $IP++
                      break
                }
                "R" { $IP++ ; break; }                                       # Remark - comment line, does nothing
                "T" { if ($line[0] -match "H") {                             # Type   - Output text to console
                          $out = (pilottype -textline $line[1] -width $printwidth)
                          $out[0..$out.length-2] | Write-Host
                          $out[-1] | Write-Host -NoNewline
                      } else {
                          (pilottype -textline $line[1] -width $printwidth) | Write-Host
                      }
                      $IP++
                      break
                }
                "U" { if ($script:variables["%uselevel"] -eq $retloc.Length) {                    # Use    - Call a subroutine
                          $retloc += @($IP + 1)
                      } else {
                          $retloc[$script:variables["%uselevel"]] = $IP + 1
                      }
                      $script:variables["%uselevel"]++
                      if (($line[1].trim())[0] -ne "*") { $line[1] = "*$($line[1].trim())" }  # if it doesn't start with a *, add one
                      $dest = $labels[$line[1].Trim()]
                      if ($dest -eq $null) { "U: Undefined Subroutine Label $($line[1].trim()) in line $IP" ; return }
                      $IP = $dest
                      break
                }
                "W" { pilotwait -seconds (expandvariables $line[1])
                      $IP++
                      break
                }
                "Y" { if ($script:variables["%matched"]) {                                        # Yes    - Type if the last M (match) resulted in a match
                          if ($line[0] -match "H") {
                              $out = (pilottype -textline $line[1] -width $printwidth)
                              $out[0..$out.length-2] | Write-Host
                              $out[-1] | Write-Host -NoNewline
                          } else {
                              (pilottype -textline $line[1] -width $printwidth) | Write-Host
                          }
                      }
                      $IP++
                      break
                }
                "*" { $IP++; break }                                         # Label, target for jump - no statement.
                default { "Unimplemented command [$($line[0][0])] encountered"; return }
            }
        } else {
            $IP++
        } 
    } else {
        $IP++
    }
}
