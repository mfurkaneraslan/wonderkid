param(
  [Parameter(Mandatory = $true)]
  [string]$SourceCsv,

  [string]$OutputJson = (Join-Path $PSScriptRoot '..\assets\data\fc26_career.json')
)

$ErrorActionPreference = 'Stop'

$leagueMeta = [ordered]@{
  '13' = @{ name = 'Premier League'; country = 'İngiltere' }
  '16' = @{ name = 'Ligue 1'; country = 'Fransa' }
  '19' = @{ name = 'Bundesliga'; country = 'Almanya' }
  '31' = @{ name = 'Serie A'; country = 'İtalya' }
  '53' = @{ name = 'La Liga'; country = 'İspanya' }
  '68' = @{ name = 'Süper Lig'; country = 'Türkiye' }
}

function To-Integer([string]$value) {
  if ([string]::IsNullOrWhiteSpace($value)) { return $null }
  return [int]$value
}

$rows = Import-Csv -LiteralPath $SourceCsv | Where-Object {
  $_.league_level -eq '1' -and $leagueMeta.Contains($_.league_id)
}

$players = foreach ($row in $rows) {
  [ordered]@{
    id = [int]$row.player_id
    shortName = $row.short_name
    longName = $row.long_name
    positions = @($row.player_positions -split ',\s*')
    overall = [math]::Min(99, ([int]$row.overall + 3))
    potential = [int]$row.potential
    age = [int]$row.age
    clubId = [int]$row.club_team_id
    clubName = $row.club_name
    leagueId = [int]$row.league_id
    nationality = $row.nationality_name
    preferredFoot = $row.preferred_foot
    pace = To-Integer $row.pace
    shooting = To-Integer $row.shooting
    passing = To-Integer $row.passing
    dribbling = To-Integer $row.dribbling
    defending = To-Integer $row.defending
    physical = To-Integer $row.physic
    gkDiving = To-Integer $row.goalkeeping_diving
    gkHandling = To-Integer $row.goalkeeping_handling
    gkKicking = To-Integer $row.goalkeeping_kicking
    gkPositioning = To-Integer $row.goalkeeping_positioning
    gkReflexes = To-Integer $row.goalkeeping_reflexes
  }
}

$leagues = foreach ($leagueId in $leagueMeta.Keys) {
  $leagueRows = @($rows | Where-Object { $_.league_id -eq $leagueId })
  $clubs = foreach ($clubGroup in ($leagueRows | Group-Object club_team_id)) {
    $clubPlayers = @($clubGroup.Group)
    $topSquad = @($clubPlayers | Sort-Object { [int]$_.overall } -Descending | Select-Object -First 18)
    $rating = [math]::Round(
      ($topSquad | Measure-Object -Property overall -Average).Average,
      0
    )

    [ordered]@{
      id = [int]$clubGroup.Name
      name = $clubPlayers[0].club_name
      rating = [int]$rating
      playerCount = $clubPlayers.Count
    }
  }

  $sortedClubs = @($clubs | Sort-Object name)
  [ordered]@{
    id = [int]$leagueId
    name = $leagueMeta[$leagueId].name
    country = $leagueMeta[$leagueId].country
    clubs = $sortedClubs
  }
}

$payload = [ordered]@{
  meta = [ordered]@{
    source = [IO.Path]::GetFileName($SourceCsv)
    snapshotDate = '2025-09-21'
    overallBoost = 3
    leagueCount = $leagues.Count
    clubCount = ($leagues.clubs | Measure-Object).Count
    playerCount = $players.Count
  }
  leagues = @($leagues)
  players = @($players)
}

$outputDirectory = Split-Path -Parent $OutputJson
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$json = $payload | ConvertTo-Json -Depth 8 -Compress
[IO.File]::WriteAllText(
  [IO.Path]::GetFullPath($OutputJson),
  $json,
  [Text.UTF8Encoding]::new($false)
)

Write-Output "Leagues: $($payload.meta.leagueCount)"
Write-Output "Clubs: $($payload.meta.clubCount)"
Write-Output "Players: $($payload.meta.playerCount)"
Write-Output "Output: $([IO.Path]::GetFullPath($OutputJson))"
