# Define the root directory to start the search
$rootDirectory = "TEST"

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
                    # Extract the FQDN from the UNC path
                    $fqdn = ($targetPath -split "\\")[2]

                    # Check if the FQDN is new and print it
                    if ($uniqueServers.Add($fqdn)) {
                        Write-Output $fqdn
                    }
                }
            } catch {
                # Optionally log errors
            }
        }
    }
}

# Start the search
Search-Directory -path $rootDirectory

# Cleanup COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
