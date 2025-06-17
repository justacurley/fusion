Import-Module UniversalDashboard
$dashboard = New-UDDashboard -Title "My Dashboard" -Content {
    New-UDPageHeader -Text "Hello from PowerShell Universal Dashboard!"
}

Start-UDDashboard -Dashboard $dashboard -Port 8080