# Wonderkid football data

`fc26_career.json` is a filtered game-data asset generated from the local
Tactix snapshot `FC26_20250921.csv`.

Included first divisions:

- Premier League (`13`)
- Ligue 1 (`16`)
- Bundesliga (`19`)
- Serie A (`31`)
- La Liga (`53`)
- Süper Lig (`68`)

Oyuncuların kariyer modu OVR değerlerine oyun dengesi için `+3` eklenir
(`99` üst sınırıyla). Bu artış üretim betiğinin bir parçasıdır.

Regenerate the asset locally with:

```powershell
pwsh tool/build_fc26_dataset.ps1 -SourceCsv <path-to-FC26_20250921.csv>
```

The source CSV is not duplicated in this repository. Verify the rights and
licence of the source dataset before commercial distribution.
