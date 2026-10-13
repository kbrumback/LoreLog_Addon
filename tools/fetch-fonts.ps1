# Downloads the bundled Google Fonts (SIL Open Font License) into LoreLog/Fonts.
# Usage: powershell -ExecutionPolicy Bypass -File tools/fetch-fonts.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $root 'LoreLog\Fonts'
$lic = Join-Path $dir 'licenses'
New-Item -ItemType Directory -Force -Path $dir, $lic | Out-Null

$fonts = @(
    @{ file = 'PlayfairDisplay-Bold';            q = 'Playfair+Display:wght@700' },
    @{ file = 'EBGaramond-Regular';              q = 'EB+Garamond:wght@400' },
    @{ file = 'EBGaramond-Italic';               q = 'EB+Garamond:ital,wght@1,400' },
    @{ file = 'IMFellEnglish-Regular';           q = 'IM+Fell+English' },
    @{ file = 'IMFellEnglish-Italic';            q = 'IM+Fell+English:ital@1' },
    @{ file = 'Cinzel-Bold';                     q = 'Cinzel:wght@700' },
    @{ file = 'CormorantGaramond-Medium';        q = 'Cormorant+Garamond:wght@500' },
    @{ file = 'CormorantGaramond-MediumItalic';  q = 'Cormorant+Garamond:ital,wght@1,500' },
    @{ file = 'Lora-Regular';                    q = 'Lora:wght@400' },
    @{ file = 'Lora-Bold';                       q = 'Lora:wght@700' },
    @{ file = 'Lora-Italic';                     q = 'Lora:ital,wght@1,400' },
    @{ file = 'UncialAntiqua-Regular';           q = 'Uncial+Antiqua' }
)

# A non-browser user agent makes the Google Fonts CSS API return plain TTF URLs.
$ua = 'Wget/1.21'
foreach ($f in $fonts) {
    $css = (Invoke-WebRequest -UseBasicParsing -UserAgent $ua "https://fonts.googleapis.com/css2?family=$($f.q)").Content
    if ($css -match 'url\((https://[^)]+\.ttf)\)') {
        Invoke-WebRequest -UseBasicParsing -UserAgent $ua $Matches[1] -OutFile (Join-Path $dir "$($f.file).ttf")
        Write-Host "OK   $($f.file).ttf"
    } else {
        Write-Warning "No TTF URL found for $($f.file)"
    }
}

$families = 'playfairdisplay', 'ebgaramond', 'imfellenglish', 'cinzel', 'cormorantgaramond', 'lora', 'uncialantiqua'
foreach ($fam in $families) {
    try {
        Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/google/fonts/main/ofl/$fam/OFL.txt" -OutFile (Join-Path $lic "$fam-OFL.txt")
        Write-Host "OK   licenses/$fam-OFL.txt"
    } catch {
        Write-Warning "License fetch failed for $fam"
    }
}

# Update World of Warcraft AddOns directory with the most up-to-date folder for this addon
$wowAddons = 'C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns'
if (Test-Path $wowAddons) {
    Copy-Item -Path (Join-Path $root 'LoreLog') -Destination $wowAddons -Recurse -Force
    Write-Host "Updated $wowAddons\LoreLog with the latest files."
}
