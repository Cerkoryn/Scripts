class Card {
    [bool]$isNew
    [bool]$isLearning
    [bool]$isReview
    [string]$front
    [string]$back
    [datetime]$lastReview
    [datetime]$nextReview
    [int]$score


    Card([string]$isNew, [string]$isLearning, [string]$isReview, [string]$front, [string]$back, [datetime]$lastReview, [datetime]$nextReview, [int]$score) {
        $this.isNew = [bool]::Parse($isNew)
        $this.isLearning = [bool]::Parse($isLearning)
        $this.isReview = [bool]::Parse($isReview)
        $this.front = $front
        $this.back = $back
        $this.lastReview = [datetime]::Parse($lastReview)
        $this.nextReview = [datetime]::Parse($nextReview)
        $this.score = $score
    }
}

function load_deck($deckName, $username) {
    $filePath = "${deckName}_${username}.csv"

    if (Test-Path $filePath) {
        $deck_csv = @(Import-Csv -Path $filePath)
        $deck = @()

        foreach ($cardData in $deck_csv) {
            # Ensure that the CSV contains the expected headers
            if ($cardData.PSObject.Properties.Name -notcontains 'front' -or
                $cardData.PSObject.Properties.Name -notcontains 'back' -or
                $cardData.PSObject.Properties.Name -notcontains 'lastReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'nextReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'isNew' -or
                $cardData.PSObject.Properties.Name -notcontains 'isLearning' -or
                $cardData.PSObject.Properties.Name -notcontains 'isReview' -or
                $cardData.PSObject.Properties.Name -notcontains 'score') {
                throw "CSV file is missing required headers."
            }
            $card = [Card]::new([bool]$cardData.isNew, [bool]$cardData.isLearning, [bool]$cardData.isReview, [string]$cardData.front, [string]$cardData.back, [datetime]::Parse($cardData.lastReview), [datetime]::Parse($cardData.nextReview), [int]$cardData.score)
            $deck += $card
        }
        return $deck
    } else {
        throw "File not found: $filePath"
    }
}
function save_deck($deck, $deckName, $username) {
    $filePath = "{0}_{1}.csv" -f $deckName, $username
    $deck | Export-Csv -Path $filePath -NoTypeInformation
}

function prompt_card($card) {
    Clear-Host
    Write-Output $card.front
    Write-Output "`n`n"
    Write-Output "Press spacebar to show answer"
    do { $key = [console]::ReadKey($true) } while ($key.Key -ne 'Spacebar')

    Clear-Host
    Write-Output $card.back
    Write-Output "`n`n"
    Write-Output "Did you know the answer?"
    Write-Output "1) No"
    Write-Output "2) Kinda"
    Write-Output "3) Yes"
    Write-Output "4) Too easy"
    do { $key = [console]::ReadKey($true) } while ($key.Key -ne 'D1' -and $key.Key -ne 'D2' -and $key.Key -ne 'D3' -and $key.Key -ne 'D4')

    switch ($key.Key) {
        'D1' {
            $card.score = 0
            $card.nextReview = Get-Date  # Review immediately
        }
        'D2' {
            $card.score = [math]::Max(1, [math]::Ceiling($card.score / 2))
            $card.nextReview = (Get-Date).AddMinutes(30 * [math]::Pow(2, $card.score - 1))  # Review in 30 minutes, then 1 hour, etc.
        }
        'D3' {
            $card.score += 1
            $card.nextReview = (Get-Date).AddMinutes(60 * [math]::Pow(2, $card.score - 1))  # Review in 1 hour, then 2 hours, etc.
        }
        'D4' {
            $card.score = ($card.score + 1) * 2
            $card.nextReview = (Get-Date).AddMinutes(120 * [math]::Pow(2, $card.score - 1))  # Review in 2 hours, then 4 hours, etc.
        }
        default {
            throw "Unexpected input received: $($key.Key). Ending review."
        }
    }
    $card.lastReview = Get-Date
}

$deckName = "module"
$username = "rwiley"
$deck = load_deck -deckName $deckName -username $username
foreach ($card in $deck) {
    $currentDate = Get-Date
    if ($card.nextReview -lt $currentDate) {
        prompt_card($card)
    }
}
Write-Output "All cards reviewed."
save_deck -deck $deck -deckName $deckName -username $username

