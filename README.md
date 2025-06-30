# DevOps Interview Task

Thank you for taking the time to do our technical test. We need to deploy a new .NET Core Web API application using a docker container.

Write code to do the following:

1. Run the automated tests
2. Package the application as a docker image
3. Deploy and run the image locally or in a public cloud

Improvements can also be made. For example:

- Make any changes to the application you think are useful for a deploy process
- Host the application in a secure fashion

The application is included under [`.\super-service`](`.\super-service`).

Your solution should be triggered by a powershell script called `Deploy.ps1`.

## Submitting

Create a Git repository which includes instructions on how to run the solution.  

## file structure

super-service/
├── src/                      # Main application source code
│   ├── Controllers/
│   │   └── TimeController.cs
│   ├── Model/
│   │   ├── IClock.cs
│   │   └── WallClock.cs
│   ├── Properties/
│   │   └── launchSettings.json
│   ├── appsettings.json
│   ├── appsettings.Development.json
│   ├── Program.cs
│   ├── Startup.cs
│   └── SuperService.csproj
├── test/                     # Unit tests
│   ├── MockClock.cs
│   ├── SuperService.UnitTests.csproj
│   └── TimeControllerTest.cs
└── https/                   # Development HTTPS certificates (used in Docker container)
|    ├── localhost.pem
|    └── localhost-key.pem
├── .env                      # Environment variables (like cert paths)
├── .gitlab-ci.yml            # used by azure cloud if we are containerizing it in cloud        
├── Dockerfile                # Docker image definition using .NET 8 and HTTPS support
├── Deploy.ps1                # PowerShell deployment script for testing, building, and running the container
└── README.md                 # Project documentation and setup instructions


# SuperService - .NET 8 Web API with Docker and HTTPS

This project is a .NET 8 Web API application called SuperService. It exposes a /time endpoint and is containerized using Docker with HTTPS support using development certificates. The deployment process is automated using a PowerShell script named Deploy.ps1.

## Contents

- .NET 8 Web API located in src folder  
- Unit tests located in test folder  
- https folder contains mkcert-generated development certificates  
- Dockerfile builds and runs the application in a secure container  
- Deploy.ps1 automates the test, build, and run process for local development  

## Prerequisites

Before running this project, make sure you have the following installed

1. Docker Desktop  
2. PowerShell (on Windows)  
3. .NET 8 SDK  
4. mkcert (for generating trusted local certificates)  

## Generating HTTPS Certificates with mkcert

1. Install mkcert if not already available

   For example, using Chocolatey  
   choco install mkcert -y

2. Run the following commands to generate the certificates

   mkcert -install  
   mkcert -key-file https/localhost-key.pem -cert-file https/localhost.pem localhost 127.0.0.1 ::1

3. This will create two certificate files inside the https directory  
   - localhost.pem  
   - localhost-key.pem  

These files will be mounted into the Docker container and used to serve HTTPS traffic on port 5001.

## Dockerfile Overview
Dockerfile Guide for SuperService (.NET 8 Web API)

The Dockerfile uses a multi-stage build

1. The first stage builds the application using the .NET 8 SDK  
2. The second stage runs the application using the lightweight Alpine-based ASP.NET runtime image  
3. HTTPS certificate and key files are copied into the container  
4. Environment variables configure the Kestrel server with the provided certificate  
5. The application listens on ports 5000 (HTTP) and 5001 (HTTPS)  

The below explains the purpose, structure, functionality, and security implications of the Dockerfile used in the SuperService project.

What Is This Dockerfile For?
This Dockerfile defines a multi-stage Docker build for a secure, production-friendly container image of a .NET 8 Web API project called SuperService. It handles:

* Building and publishing the .NET application
* Running it on a lightweight, secure runtime
* Enabling HTTPS using development certificates from mkcert
* Running the container as a non-root user

File Location

super-service/
├── Dockerfile
├── https/
│   ├── localhost.pem
│   └── localhost-key.pem

The Dockerfile assumes our mkcert certificates are already present inside the https/ directory.

Breakdown of the Dockerfile (Explained Step-by-Step)

FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
 
* The above line starts with the official .NET 8 SDK image, using the Alpine variant for a smaller footprint.
* This stage is used for building and publishing the project.

WORKDIR /app
COPY ./src ./src
COPY ./test ./test
WORKDIR /app/src
RUN dotnet restore
RUN dotnet publish -c Release -o /app/out

* Sets working directory inside the container.
* Copies both source and test projects.
* Restores NuGet packages and publishes the app into the /app/out folder.

* The above steps are performed during the time of image build

FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime

* Runtime-only image is much smaller and contains no SDK tools.
* This stage hosts the final application that was built in the previous stage.

WORKDIR /app
RUN adduser -D appuser
USER appuser

* Creates a non-root user (appuser) for improved container security.
* By default, containers run as root. This step reduces risk of privilege escalation.

COPY --from=build /app/out ./ 

* Copies only the published output from the previous stage. This avoids bloating the image with unnecessary build tools.

COPY https/localhost.pem /https/localhost.pem
COPY https/localhost-key.pem /https/localhost-key.pem

* These files are required by the app to serve traffic over HTTPS (port 5001).
* Adds the HTTPS certificate and private key from the local https/ directory.

ENV ASPNETCORE_Kestrel__Certificates__Default__Path="/https/localhost.pem"
ENV ASPNETCORE_Kestrel__Certificates__Default__KeyPath="/https/localhost-key.pem"
ENV ASPNETCORE_URLS="https://+:5001;http://+:5000"


* These environment variables tell Kestrel (the built-in ASP.NET Core web server):
* Use the provided certificate and key
* Listen on ports 5000 (HTTP) and 5001 (HTTPS)

EXPOSE 5000
EXPOSE 5001

* Makes the container’s ports available to the host.

ENTRYPOINT ["dotnet", "SuperService.dll"]

* Starts the application inside the container.

## How to Use This Dockerfile
* Generate certificates using mkcert : use the below commands

mkcert -install
mkcert -key-file https/localhost-key.pem -cert-file https/localhost.pem localhost 127.0.0.1 ::1

* Build the Docker image:

docker build -t super-service:latest .

* Run the container locally:

docker run -d -p 5000:5000 -p 5001:5001 --name super-service \
  -v ${PWD}/https:/https \
  super-service:latest
Access the application:

HTTPS: https://localhost:5001/time

HTTP: http://localhost:5000/time

We should ensure our browser trusts the mkcert certificate.

## Why HTTPS with mkcert?
mkcert allows us to generate trusted development certificates that simulate real HTTPS environments.
Helps catch mixed content, CORS, and cookie issues early during local development.
Improves parity between local and production.

## Deploy.ps1 Overview

The Deploy.ps1 script performs the following steps

1. Runs all unit tests in the test directory  
2. If the tests pass, it builds the Docker image  
3. It checks if any Docker containers are using ports 5000 or 5001 and stops them  
4. It checks if a container with the same name already exists and removes it  
5. It runs a new container, mapping ports 5000 and 5001 from the container to the host  
6. The script mounts the local https folder into the container  
7. It opens https://localhost:5001/time in the browser  

## How to Run the Application

1. Open PowerShell and navigate to the root of the project directory  

2. Run the command  
   ./Deploy.ps1  

3. This will  
   - Execute unit tests  
   - Build the Docker image  
   - Stop any conflicting containers  
   - Launch a new container with HTTPS binding  
   - Open the browser to https://localhost:5001/time  

## PowerShell Deployment Script Explanation (Deploy.ps1)

* The Deploy.ps1 script automates the entire local development workflow:
* Runs unit tests
* Builds the Docker image
* Safely handles existing containers
* Runs a secure container with HTTPS
* Opens the application in a browser

## Script Parameters
param (
    [string]$projectPath = ".",
    [string]$imageName = "super-service:latest",
    [string]$containerName = "super-service-api",
    [switch]$runLocally = $true
)
* projectPath: Specifies the path to the project directory (default is current directory).
* imageName: Name/tag for the Docker image to be built.
* containerName: Name to assign to the running container.
* runLocally: A flag that determines whether to deploy locally or skip local deployment.

Function: Stop-ContainersOnPort

function Stop-ContainersOnPort {
    param ([int[]]$portsToCheck)
    ...
}
This function:

* Accepts an array of ports (portsToCheck)
* Checks if any running containers are using those ports (e.g., 5000 or 5001)
* If yes, it forcibly stops and removes those containers
* This ensures port conflicts are avoided before starting a new container.

Step 1: Run Unit Tests

* Write-Host "Running automated tests..."
* Push-Location $projectPath

if (Test-Path ".\test\SuperService.UnitTests.csproj") {
    dotnet test .\test\SuperService.UnitTests.csproj
    ...
}

Pop-Location
* Changes the working directory to the project folder
* Checks if the test project exists
* Runs tests using dotnet test
* If tests fail, deployment is aborted

Step 2: Build Docker Image

Write-Host "Building Docker image..."
docker build -t $imageName $projectPath
* Builds the Docker image using the provided Dockerfile

Tags it with the name provided via $imageName
If the build fails, the script exits with an error

Step 3: Run Container (If -runLocally is specified)

if ($runLocally) {
    ...
}
If -runLocally is used (which it is by default), the following happens:

a. Free Up Ports
* Stop-ContainersOnPort -portsToCheck @(5000, 5001)
* Stops any existing containers using ports 5000 or 5001 to avoid binding errors

b. Remove Existing Container by Name

$existingContainer = docker ps -a --filter "name=^/${containerName}$" ...
Checks for an existing container with the same name

Removes it to prevent naming conflicts

c. Run New Container

docker run -d `
    -p 5000:5000 -p 5001:5001 `
    --name $containerName `
    -v "${PWD}\https:/https" `
    $imageName
* Starts a container in detached mode (-d)
* Maps container ports 5000 and 5001 to local machine
* Mounts the https/ folder to /https inside the container (used for TLS certs)
* Runs the container using the image just built

d. Open in Browser

* Start-Process "https://localhost:5001/time"
* Waits a few seconds, then opens the /time endpoint in the default browser

Else: Cloud Deployment Placeholder

else {
    Write-Host "Cloud deployment not implemented."
}
This block is reserved for future enhancement — such as cloud deployment (Azure, AWS, etc.).

## How to Use Deploy.ps1

The `Deploy.ps1` script automates local testing, Docker image creation, and running the application securely with HTTPS. This script is designed for local development and validation of the `.NET 8` Web API (`SuperService`) container.

### Prerequisites

Ensure we have the following installed:

* Docker Desktop (running)
* PowerShell (on Windows)
* .NET 8 SDK
* mkcert (for local HTTPS certificates)

### Folder Structure

The project should be structured like this:

```
super-service/
├── src/
├── test/
├── https/
│   ├── localhost.pem
│   └── localhost-key.pem
├── Dockerfile
├── Deploy.ps1
└── .env (optional)
```

### Step-by-Step Usage

1. **Open PowerShell**
   Navigate to the root of the project (where `Deploy.ps1` is located):

   ```powershell
   cd path\to\super-service
   ```

2. **Run the script**
   Execute the script to test, build, and run the container:

   ```powershell
   .\Deploy.ps1
   ```

   This will:

   * Run unit tests from the `test/` folder
   * Build a Docker image using the Dockerfile
   * Check and stop containers using ports `5000` and `5001`
   * Remove old containers named `super-service-api`
   * Launch a new container with the image and mounted HTTPS certs
   * Open the browser to `https://localhost:5001/time`

3. **Verify**
   our API should be available at:

   * `https://localhost:5001/time` (secured with mkcert-generated cert)
   * `http://localhost:5000/time` (insecure fallback)

### Optional: Skip Local Run

To only run tests and build the Docker image without launching the container:

```powershell
.\Deploy.ps1 -runLocally:$false
```

This is useful for use in CI environments or testing image builds only.

### Troubleshooting

| Problem                    | Cause                                      | Solution                                                                            |
| -------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------- |
| Browser shows "Not Secure" | Certificate not trusted                    | Run `mkcert -install` and restart our browser                                      |
| Port already in use        | Another app or container is using the port | Run `docker ps`, find the container, then `docker rm -f <id>`                       |
| Tests fail                 | Failing unit tests in `test/` folder       | Open and debug the test failures                                                    |
| HTTPS not working          | Certs not found or not mounted correctly   | Ensure `https/localhost.pem` and `localhost-key.pem` exist and are mounted properly |


## Accessing the API

- HTTPS endpoint  
  https://localhost:5001/time  

- HTTP endpoint  
  http://localhost:5000/time  

Both endpoints are accessible locally. The HTTPS endpoint uses the mkcert-generated certificate.

## Common Issues

1. If Edge or other browsers say the site is Not Secure  
   - Ensure mkcert root certificate is trusted  
   - Try accessing in Chrome  
   - Clear browser cache  

2. If the container fails to start  
   - Check if Docker is running  
   - Make sure ports 5000 and 5001 are free  
   - Use docker ps and docker rm -f container ID to remove old containers  

3. If the browser says the certificate is valid but the site is not fully secure  
   - Ensure all content is served over HTTPS  
   - Open browser developer tools and check for mixed content warnings  

## Next Steps

- Add CI/CD using GitHub Actions or Azure DevOps  
- Use Docker Compose for multi-container scenarios  
- Deploy to cloud platforms like Azure or AWS  

## Conclusion

This setup provides a secure local development environment using

- HTTPS with mkcert  
- Docker containers using non-root users  
- Automated test and deployment  
- Clean separation of build and runtime layers  

We are now ready to develop and test our .NET 8 Web API application with confidence in a secure and automated local environment.