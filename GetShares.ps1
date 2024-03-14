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
    # Collect all .lnk files first
    $lnkFiles = Get-ChildItem -Path $path -Recurse -Filter *.lnk -ErrorAction SilentlyContinue

    # Process .lnk files in parallel and collect results
    $results = $lnkFiles | ForEach-Object -Parallel {
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
                Write-Output $uniqueShare
            }
        } catch {
            Write-Error "Error processing file $($_.FullName): $_"
        } finally {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        }
        return $uniqueShare
    } -ThrottleLimit 10

    $mutex = [System.Threading.Mutex]::new($false, "HashSetLock")

    # Add the results to the HashSet and output file outside the parallel block
    foreach ($share in $results) {
        if ($null -ne $share) {
            # Synchronize access to the shared HashSet
            try {
                $mutex.WaitOne()
                if ($uniqueServers.Add($share)) {
                    Add-Content -Value $share -Path $outputFile
                    Write-Host $share
                }
            } finally {
                $mutex.ReleaseMutex()
            }
        }
    }
    $mutex.Dispose()
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
