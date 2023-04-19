function Get-PrimeFactors($number) {
    $factors = @()
    $divisor = 2
    while ($number -gt 1) {
        if ($number % $divisor -eq 0) {
            $factors += $divisor
            $number /= $divisor
        }
        else {
            $divisor++
        }
    }
    return $factors -join ";"
}

# Define the API endpoint URL
$url = "https://datausa.io/api/data?drilldowns=State&measures=Population"

# Get the data from the API as JSON
$data = Invoke-RestMethod -Uri $url

# Extract the state names and years from the data
$states = ($data.data | Group-Object 'State').Name
$years = ($data.data | Group-Object 'ID Year').Name | Sort-Object

# Create an empty array to store the CSV rows
$rows = @()

# Loop through each state
foreach ($state in $states) {
    # Initialize variables to calculate year-over-year population change
    $OldPop = $null
    $Pop_pct = @()
    $populations = @()

    # Loop through each year
    foreach ($year in $years) {
        # Get the population for the current state and year
        $pop = $data.data | Where-Object {($_.State -eq $state -and $_.Year -eq $year) } | Select-Object -ExpandProperty Population

        # Calculate year-over-year population change
        if ($OldPop) {
            $Pop_pct += [Math]::Round(($pop - $OldPop) / $OldPop * 100, 2)
        }
        $OldPop = $pop
        # Add the final population value to the $populations array
        $populations += $OldPop
    }

    # Get the prime factorization of the final year's population
    $prime_factors = Get-PrimeFactors -number $OldPop -join ";"

    # Format the row as an array of values
    $row = @(
        $state,
        ($populations -join "; "),
        "($($Pop_pct -join "%; "))",
        $prime_factors
    )

    # Add the row to the array of rows
    $rows += $row
}

# Define the CSV header
$header = "State Name" + ($years | Sort-Object)

# Combine the header and rows into a single array
$output = @($header), $rows

# Output the array as a CSV
$output | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Set-Content -Encoding UTF8 -Path "C:\population_data.csv"