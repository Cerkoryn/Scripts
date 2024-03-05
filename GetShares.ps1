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

    # Get all items in the current directory without stopping on errors
    $items = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue

    foreach ($item in $items) {
        if ($item.Extension -eq ".lnk") {
            try {
                # Extract the target path of the shortcut
                $lnk = $shell.CreateShortcut($item.FullName)
                $targetPath = $lnk.TargetPath

                # Check if the target path looks like a UNC path
                if ($targetPath.StartsWith("\\\")) {
                    # Extract the FQDN from the UNC path
                    $fqdn = ($targetPath -split "\\")[2]

                    # Check if the FQDN is new and print it
                    if ($uniqueServers.Add($fqdn)) {
                        Write-Output $fqdn
                    }
                }
            } catch {
                # Ignore errors related to processing the shortcut and continue
            }
        }
    }
}

# Start the search
Search-Directory -path $rootDirectory

# Cleanup COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
