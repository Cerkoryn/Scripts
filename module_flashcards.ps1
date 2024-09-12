$ratings = @{
    again = 1
    hard = 2
    good = 3
    easy = 4
}
class Card {
    [bool]$isNew
    [bool]$isLearning
    [bool]$isReview
    [hashtable]$customData

    Card([string]$isNew, [string]$isLearning, [string]$isReview) {
        $this.isNew = [bool]::Parse($isNew)
        $this.isLearning = [bool]::Parse($isLearning)
        $this.isReview = [bool]::Parse($isReview)
        $this.customData = @{}
    }
}

function load_deck($deckName, $username) {
    $filePath = "$deckName`_$username.csv"
    if (Test-Path $filePath) {
        $deck_csv = @(Import-Csv -Path $filePath)
        $deck = @()

        foreach ($cardData in $deck_csv) {
            # Ensure that the CSV contains the expected headers
            if ($cardData.PSObject.Properties.Name -notcontains 'isNew' -or
                $cardData.PSObject.Properties.Name -notcontains 'isLearning' -or
                $cardData.PSObject.Properties.Name -notcontains 'isReview') {
                throw "CSV file is missing required headers."
            }
            $card = [Card]::new($cardData.isNew, $cardData.isLearning, $cardData.isReview)
            $deck += $card
        }
        return $deck
    } else {
        throw "File not found: $filePath"
    }
}

function constrain_difficulty($difficulty) {
    return [math]::Min([math]::Max([math]::Round($difficulty, 2), 1), 10)
}

function forgetting_curve($elapsed_days, $stability) {
    $decay = -0.5
    $factor = [math]::Pow(0.9, 1 / $decay) - 1
    return [math]::Pow(1 + $factor * $elapsed_days / $stability, $decay)
}

function next_interval($stability, $requestRetention, $maximumInterval) {
    $decay = -0.5
    $factor = [math]::Pow(0.9, 1 / $decay) - 1
    $new_interval = $stability / $factor * ([math]::Pow($requestRetention, 1 / $decay) - 1)
    return [math]::Min([math]::Max([math]::Round($new_interval), 1), $maximumInterval)
}

function next_difficulty($d, $rating, $w, $ratings) {
    $next_d = $d - $w[6] * ($ratings[$rating] - 3)
    return constrain_difficulty(mean_reversion(init_difficulty("easy", $w, $ratings), $next_d, $w))
}

function mean_reversion($init, $current, $w) {
    return $w[7] * $init + (1 - $w[7]) * $current
}

function next_recall_stability($d, $s, $r, $rating, $w) {
    $hardPenalty = if ($rating -eq "hard") { $w[15] } else { 1 }
    $easyBonus = if ($rating -eq "easy") { $w[16] } else { 1 }
    return [math]::Round($s * (1 + [math]::Exp($w[8]) * (11 - $d) * [math]::Pow($s, -$w[9]) * ([math]::Exp((1 - $r) * $w[10]) - 1) * $hardPenalty * $easyBonus), 2)
}

function next_forget_stability($d, $s, $r, $w) {
    return [math]::Round([math]::Min($w[11] * [math]::Pow($d, -$w[12]) * ([math]::Pow($s + 1, $w[13]) - 1) * [math]::Exp((1 - $r) * $w[14]), $s), 2)
}

function next_short_term_stability($s, $rating, $w, $ratings) {
    return [math]::Round($s * [math]::Exp($w[17] * ($rating - 3 + $w[18])), 2)
}

function init_states($w, $ratings) {
    $customData = @{
        again = @{
            d = init_difficulty("again", $w, $ratings)
            s = init_stability("again", $w, $ratings)
        }
        hard = @{
            d = init_difficulty("hard", $w, $ratings)
            s = init_stability("hard", $w, $ratings)
        }
        good = @{
            d = init_difficulty("good", $w, $ratings)
            s = init_stability("good", $w, $ratings)
        }
        easy = @{
            d = init_difficulty("easy", $w, $ratings)
            s = init_stability("easy", $w, $ratings)
        }
    }
    return $customData
}

function init_difficulty($rating, $w, $ratings) {
    $difficulty = $w[4] - [math]::Exp($w[5] * ($ratings[$rating] - 1)) + 1
    $constrained_difficulty = constrain_difficulty($difficulty)
    return [math]::Round($constrained_difficulty, 2)
}

function init_stability($rating, $w, $ratings) {
    return [math]::Round([math]::Max($w[$ratings[$rating] - 1], 0.1), 2)
}

function convert_states($states, $w) {
    $scheduledDays = if ($states.current.normal) { $states.current.normal.review.scheduledDays } else { $states.current.filtered.rescheduling.originalState.review.scheduledDays }
    $easeFactor = if ($states.current.normal) { $states.current.normal.review.easeFactor } else { $states.current.filtered.rescheduling.originalState.review.easeFactor }
    $old_s = [math]::Round([math]::Max($scheduledDays, 0.1), 2)
    $old_d = constrain_difficulty(11 - ($easeFactor - 1) / ([math]::Exp($w[8]) * [math]::Pow($old_s, -$w[9]) * ([math]::Exp(0.1 * $w[10]) - 1)))
    $customData = @{
        again = @{
            d = $old_d
            s = $old_s
        }
        hard = @{
            d = $old_d
            s = $old_s
        }
        good = @{
            d = $old_d
            s = $old_s
        }
        easy = @{
            d = $old_d
            s = $old_s
        }
    }
    return $customData
}

$w = @(0.41, 1.18, 3.04, 15.24, 7.14, 0.64, 1.00, 0.06, 1.65, 0.17, 1.11, 2.02, 0.09, 0.30, 2.12, 0.24, 2.94, 0.48, 0.64) # Algorithm weights
$requestRetention = 0.9
$maximumInterval = 36500
$decay = -0.5
$factor = [math]::Pow(0.9, (1 / $decay)) - 1

$deck = load_deck("module", "rwiley")

foreach ($card in $deck) {
    if ($card.isNew) {

    }
    elseif ($card.isLearning) {

    }
    elseif ($card.isReview) {
        
    }
}
