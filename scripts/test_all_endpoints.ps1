$endpoints = @(
    @{ name = "Metadata"; method = "GET"; url = "http://localhost:3001/api/metadata" },
    @{ name = "Market Overview"; method = "GET"; url = "http://localhost:3001/api/market/overview" },
    @{ name = "Market Skills"; method = "GET"; url = "http://localhost:3001/api/market/skills" },
    @{ name = "Market Salary"; method = "GET"; url = "http://localhost:3001/api/market/salary" },
    @{ name = "Market Correlation"; method = "GET"; url = "http://localhost:3001/api/market/correlation" },
    @{ name = "Career Matches"; method = "POST"; url = "http://localhost:3001/api/career/matches"; body = '{"skills":["Python","SQL"]}' },
    @{ name = "Career Detail"; method = "POST"; url = "http://localhost:3001/api/career/detail"; body = '{"skills":["Python","SQL"],"role":"Data Analyst"}' },
    @{ name = "Career Compare"; method = "POST"; url = "http://localhost:3001/api/career/compare"; body = '{"skills":["Python","SQL"],"role_a":"Data Analyst","role_b":"Data Scientist"}' },
    @{ name = "Skill Gap"; method = "POST"; url = "http://localhost:3001/api/skills/gap"; body = '{"skills":["Python","SQL"],"role":"Data Analyst"}' },
    @{ name = "Skill Simulation"; method = "POST"; url = "http://localhost:3001/api/skills/simulate"; body = '{"current_skills":["Python","SQL"],"proposed_skills":["Python","SQL","Tableau"],"role":"Data Analyst"}' },
    @{ name = "JD Analysis"; method = "POST"; url = "http://localhost:3001/api/job-description/analyze"; body = '{"text":"Looking for Python, SQL, Tableau engineer","candidate_skills":["Python","SQL"],"target_role":"Data Analyst"}' },
    @{ name = "Salary Prediction"; method = "POST"; url = "http://localhost:3001/api/salary/predict"; body = '{"experience":4,"skill_count":6,"education":"B.Tech","company_size":"Large","location_tier":"Tier 1"}' },
    @{ name = "Data Quality"; method = "GET"; url = "http://localhost:3001/api/data-quality" }
)

foreach ($ep in $endpoints) {
    try {
        if ($ep.method -eq "GET") {
            $res = Invoke-RestMethod -Uri $ep.url -Method GET
        } else {
            $res = Invoke-RestMethod -Uri $ep.url -Method POST -ContentType "application/json" -Body $ep.body
        }
        $status = if ($res.success) { "PASS" } else { "FAIL" }
        Write-Host "[$status] $($ep.name)"
    } catch {
        Write-Host "[FAIL] $($ep.name): $($_.Exception.Message)"
    }
}
