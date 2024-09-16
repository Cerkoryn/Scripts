$deckName = "module"
$filePath = "$deckName.csv"

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

$front = Read-Host "Enter the front of the card"
$back = Read-Host "Enter the back of the card"

if ($front -like '*"*"*' -or $back -like '*"*"*') {
    Write-Output "Error: Quotation marks are not allowed on the card without breaking it. Exiting."
    exit
}

Write-Output "Front: $front"
Write-Output "Back: $back"
$confirmation = Read-Host "Is this correct? (yes/no)"

if ($confirmation -ne "yes") {
    Write-Output "Card not added. Exiting."
    exit
}

$newCard = [Card]::new($front, $back, (Get-Date), (Get-Date), 0)

function load_and_parse_deck($filePath) {
    if (Test-Path $filePath) {
        try {
            $deck_csv = @(Import-Csv -Path $filePath)
            $deck = @()
            foreach ($cardData in $deck_csv) {
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
            return $deck
        } catch {
            Write-Output "Error: Unable to import the file $filePath. Exiting."
            Write-Output "Exception Message: $($_.Exception.Message)"
            exit
        }
    } else {
        Write-Output "Error: File not found: $filePath. Exiting."
        exit
    }
}

$deck = load_and_parse_deck $filePath
# Check if the front of the card is unique
if ($deck | Where-Object { $_.front -eq $newCard.front }) {
    Write-Output "Error: A card with this front already exists. Exiting."
    exit
}

$deck += $newCard
$deck | Export-Csv -Path $filePath -NoTypeInformation
Write-Output "Card added successfully."
