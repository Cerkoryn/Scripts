$interval_list = @(0, 5, 25, 120, 600, 3600, 18000, 86400)
$username = Read-Host "Enter your first initial and last name.  I.e., John Smith is jsmith."
$allowedUsernames = @("user1", "user2", "user3")

if ([string]::IsNullOrEmpty($username)) {
    Write-Output "Username cannot be null or empty. Exiting."
    exit
}
if ($allowedUsernames -notcontains $username) {
    Write-Output "Username not in list of names. Exiting."
    exit
}

class Card {
    [string]$front
    [string]$back
    [datetime]$lastReview
    [datetime]$nextReview
    [int]$interval

    Card([string]$front, [string]$back, [datetime]$lastReview, [datetime]$nextReview, [int]$interval) {
        $this.front = $front
        $this.back = $back
        $this.lastReview = [datetime]::Parse($lastReview)
        $this.nextReview = [datetime]::Parse($nextReview)
        $this.interval = $interval
    }
}

function load_deck($deckName, $username) {
    $userDeckPath = "${deckName}_${username}.csv"
    $globalDeckPath = "${deckName}.csv"
    $deck = @()

    if (Test-Path $userDeckPath) {
        $userDeck_csv = @(Import-Csv -Path $userDeckPath)
        foreach ($cardData in $userDeck_csv) {
            if ($cardData.PSObject.Properties.Name -notcontains 'front' -or
                $cardData.PSObject.Properties.Name -notcontains 'back' -or
                $cardData.PSObject.Properties.Name -notcontains 'lastReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'nextReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'interval') {
                throw "CSV file is missing required headers."
            }
            $card = [Card]::new([string]$cardData.front, [string]$cardData.back, [datetime]::Parse($cardData.lastReview), [datetime]::Parse($cardData.nextReview), [int]$cardData.interval)
            $deck += $card
        }
    }

    if (Test-Path $globalDeckPath) {
        $globalDeck_csv = @(Import-Csv -Path $globalDeckPath)
        foreach ($cardData in $globalDeck_csv) {
            if ($cardData.PSObject.Properties.Name -notcontains 'front' -or
                $cardData.PSObject.Properties.Name -notcontains 'back' -or
                $cardData.PSObject.Properties.Name -notcontains 'lastReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'nextReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'interval') {
                throw "CSV file is missing required headers."
            }
            $card = [Card]::new([string]$cardData.front, [string]$cardData.back, [datetime]::Parse($cardData.lastReview), [datetime]::Parse($cardData.nextReview), [int]$cardData.interval)
            if (-not ($deck | Where-Object { $_.front -eq $card.front -and $_.back -eq $card.back })) {
                $deck += $card
            }
        }
    } else {
        throw "File not found: $globalDeckPath"
    }

    return $deck
}

function save_deck($deck, $deckName, $username) {
    $filePath = "{0}_{1}.csv" -f $deckName, $username
    $deck | Export-Csv -Path $filePath -NoTypeInformation
}

function center_text($text) {
    $windowWidth = [console]::WindowWidth
    $padding = [math]::Max(0, ($windowWidth - $text.Length) / 2)
    return " " * $padding + $text
}

function prompt_card($card) {
    Clear-Host
    $frontText = $card.front -replace '\\n', "`n"
    Write-Output (center_text $frontText)
    Write-Output "`n`n"
    Write-Output (center_text "Press spacebar to show answer")
    do { $key = [console]::ReadKey($true) } while ($key.Key -ne 'Spacebar')

    Clear-Host
    $backText = $card.back -replace '\\n', "`n"
    Write-Output (center_text $backText)
    Write-Output "`n`n"
    Write-Output (center_text "Did you know the answer?")
    Write-Output (center_text "1) No")
    Write-Output (center_text "2) Kinda")
    Write-Output (center_text "3) Yes")
    Write-Output (center_text "4) Too easy")
    do { $key = [console]::ReadKey($true) } while ($key.Key -ne 'D1' -and $key.Key -ne 'D2' -and $key.Key -ne 'D3' -and $key.Key -ne 'D4')
    
    switch ($key.Key) {
        'D1' {
            $card.interval = 0
            $card.nextReview = Get-Date  # Review immediately
        }
        'D2' {
            # Keep the interval the same and add that many seconds to today's date
            $card.nextReview = (Get-Date).AddSeconds($card.interval)
        }
        'D3' {
            # Increment to the next interval and add it to today's date
            $currentIndex = [array]::IndexOf($interval_list, $card.interval)
            if ($currentIndex -lt ($interval_list.Length - 1)) {
                $card.interval = $interval_list[$currentIndex + 1]
            }
            $card.nextReview = (Get-Date).AddSeconds($card.interval)
        }
        'D4' {
            # Increment by two intervals and add it to today's date
            $currentIndex = [array]::IndexOf($interval_list, $card.interval)
            if ($currentIndex -lt ($interval_list.Length - 2)) {
                $card.interval = $interval_list[$currentIndex + 2]
            } elseif ($currentIndex -lt ($interval_list.Length - 1)) {
                $card.interval = $interval_list[$currentIndex + 1]
            }
            $card.nextReview = (Get-Date).AddSeconds($card.interval)
        }
        default {
            throw "Unexpected input received: $($key.Key). Ending review."
        }
    }
    $card.lastReview = Get-Date
}

$deckName = "module"
$deck = load_deck -deckName $deckName -username $username
foreach ($card in $deck) {
    $currentDate = Get-Date
    if ($card.nextReview -lt $currentDate) {
        prompt_card($card) 
    }
}
Write-Output "All cards reviewed."
save_deck -deck $deck -deckName $deckName -username $username