# Stop on error
$ErrorActionPreference = "Stop"

Write-Host "Running unit tests"
dotnet test ./test/SuperService.UnitTests.csproj

Write-Host "Building Docker image"
docker build -t super-service .

Write-Host "Running Docker container"
docker rm -f super-service-container 2>$null
docker run -d -p 8080:80 --name super-service-container super-service

Write-Host "Deployment complete! App is available at: http://localhost:5000/time"
