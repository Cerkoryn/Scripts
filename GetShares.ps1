# Read from a list of directories and use each line as $rootDirectory
$directoriesFile = "path_to_directories_file.txt" # Replace with the actual file path
$outputFile = "path_to_output_file.txt"           # Replace with the actual file path

# Create an empty HashSet to store unique FQDNs
$uniqueServers = New-Object System.Collections.Generic.HashSet[string]

# Recursive function to find and process .lnk files
function Search-Directory {
    param (
        [string]$path
    )
    # Process .lnk files in parallel and collect results
    Get-ChildItem -Path $path -Recurse -Filter *.lnk -ErrorAction SilentlyContinue | ForEach-Object -Parallel {
        $shell = New-Object -ComObject WScript.Shell
        $uniqueShare = $null
        try {
            $lnk = $shell.CreateShortcut($_.FullName)
            $targetPath = $lnk.TargetPath
            if ($targetPath.StartsWith("\\")) {
                $splitPath = $targetPath -split "\\"
                $fqdn = $splitPath[2]
                $firstFolder = $splitPath[3]
                $uniqueShare = "\\$fqdn\$firstFolder"
                # Check if we have read access to the share
                if (Test-Path -Path $uniqueShare -PathType Container) {
                    $uniqueShare
                } else {
                    $null
                }
            }
        } catch {
            Write-Error "Error processing file $($_.FullName): $_"
        } finally {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        return $uniqueShare
    } -ThrottleLimit 10 | Where-Object { $_ -ne $null } | ForEach-Object {
        if ($uniqueServers.Add($_)) {
            Add-Content -Value $_ -Path $outputFile
            Write-Host $_
        }
    }
}


# Initialize a queue with the root directories
$queue = New-Object System.Collections.Generic.Queue[string]
Get-Content -Path $directoriesFile | ForEach-Object {
    $queue.Enqueue($_)
}

# Process each directory in the queue
while ($queue.Count -gt 0) {
    $currentPath = $queue.Dequeue()
    Search-Directory -path $currentPath
}
