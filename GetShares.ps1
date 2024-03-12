# Read from a list of directories and use each line as $rootDirectory
$directoriesFile = "path_to_directories_file.txt" # Replace with the actual file path
$outputFile = "path_to_output_file.txt"           # Replace with the actual file path

# Create an empty HashSet to store unique FQDNs
$uniqueServers = New-Object System.Collections.Generic.HashSet[string]

# Define the Shell.Application COM object to extract shortcut target paths
$shell = New-Object -ComObject WScript.Shell

# Recursive function to find and process .lnk files
function Search-Directory {
    param (
        [string]$path
    )
    # Process items in the current directory one by one, including directories but ignoring errors
    Get-ChildItem -Path $path -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        # Check if the item is a file and has a .lnk extension
        if (!$_.PSIsContainer -and $_.Extension -eq ".lnk") {
            try {
                # Extract the target path of the shortcut
                $lnk = $shell.CreateShortcut($_.FullName)
                $targetPath = $lnk.TargetPath
                # Check if the target path looks like a UNC path
                if ($targetPath.StartsWith("\\")) {
                    # Extract the FQDN and the first folder in the share from the UNC path
                    $splitPath = $targetPath -split "\\"
                    $fqdn = $splitPath[2]
                    $firstFolder = $splitPath[3]
                    $uniqueShare = "\\$fqdn\$firstFolder"
                    # Check if we have read access to the unique network/file share
                    $hasReadAccess = Test-Path -Path $uniqueShare -PathType Container
                    # Check if the unique network/file share is new and if we have read access, then print it
                    if ($uniqueServers.Add($uniqueShare) -and $hasReadAccess) {
                        Add-Content -Value $uniqueShare -Path $outputFile
                        Write-Host $uniqueShare
                        # Recursively search the new unique share
                        Search-Directory -path $uniqueShare
                    }
                }
            } catch {
                # Optionally log errors
            }
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

# Cleanup COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
