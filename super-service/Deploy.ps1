param (
    [string]$projectPath = ".",
    [string]$imageName = "super-service:latest",
    [string]$containerName = "super-service-api",
    [switch]$runLocally = $true
)

function Stop-ContainersOnPort {
    param ([int[]]$portsToCheck)
    foreach ($port in $portsToCheck) {
        $containers = docker ps --format "{{.ID}} {{.Ports}}" | Where-Object { $_ -match "0\.0\.0\.0:$port" }
        foreach ($line in $containers) {
            $containerId = ($line -split " ")[0]
            Write-Host "Stopping container using port ${port}: $containerId"
            docker rm -f $containerId | Out-Null
        }
    }
}

Write-Host "Running automated tests..."
Push-Location $projectPath

if (Test-Path ".\test\SuperService.UnitTests.csproj") {
    dotnet test .\test\SuperService.UnitTests.csproj
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed. Aborting deployment."
        Exit 1
    }
} else {
    Write-Host "No test project found. Skipping tests."
}
Pop-Location

Write-Host "Building Docker image..."
docker build -t $imageName $projectPath
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed. Aborting deployment."
    Exit 1
}

if ($runLocally) {
    Write-Host "Running container on ports 5000 and 5001..."

    Stop-ContainersOnPort -portsToCheck @(5000, 5001)

    $existingContainer = docker ps -a --filter "name=^/${containerName}$" --format "{{.ID}}"
    if ($existingContainer) {
        Write-Host "Removing existing container $containerName"
        docker rm -f $containerName | Out-Null
    }

    docker run -d `
        -p 5000:5000 -p 5001:5001 `
        --name $containerName `
        -v "${PWD}\https:/https" `
        $imageName

    if ($LASTEXITCODE -eq 0) {
        Write-Host "Application is running at https://localhost:5001/time"
        Start-Sleep -Seconds 3
        Start-Process "https://localhost:5001/time"
    } else {
        Write-Error "Failed to start container."
    }
} else {
    Write-Host "Cloud deployment not implemented."
}