# SuperService - Secure .NET 8 Web API with Docker and Automated Deployment

SuperService is a .NET 8 Web API that exposes a /time endpoint. It is designed to run securely in a local Docker environment using mkcert-generated HTTPS certificates. Deployment, testing, and container lifecycle are automated using a PowerShell script.

## Overview

This solution demonstrates:

- Secure local hosting over HTTPS using mkcert
- Multistage Dockerfile using .NET 8 SDK and ASP.NET runtime
- Automated testing and container management using PowerShell
- Non-root execution in Docker containers for enhanced security
- Modular project structure ready for CI/CD pipelines

## Project Structure

super-service/
├── src/
│   ├── Controllers/
│   ├── Model/
│   ├── Properties/
│   ├── Program.cs
│   ├── Startup.cs
│   ├── appsettings.json
│   ├── appsettings.Development.json
│   └── SuperService.csproj
├── test/
│   ├── TimeControllerTest.cs
│   ├── SuperService.UnitTests.csproj
├── https/
│   ├── localhost.pem
│   └── localhost-key.pem
├── .env
├── Dockerfile
├── Deploy.ps1
└── README.md

## Prerequisites

Ensure the following tools are installed:

- Docker Desktop
- PowerShell
- .NET 8 SDK
- mkcert

## Setting Up HTTPS Certificates

1. Install mkcert (example using Chocolatey on Windows)

   choco install mkcert -y

2. Initialize the trusted local Certificate Authority

   mkcert -install

3. Generate certificate and key for localhost

   mkcert -key-file https/localhost-key.pem -cert-file https/localhost.pem localhost 127.0.0.1 ::1

## Dockerfile Explanation

- Stage 1 uses the .NET 8 SDK to restore and publish the application
- Stage 2 uses the lightweight ASP.NET Alpine runtime
- Certificates from the https folder are copied into the container
- The Kestrel server is configured via environment variables
- Ports 5000 (HTTP) and 5001 (HTTPS) are exposed

## Deploy.ps1 Workflow

When you run Deploy.ps1, the script performs:

1. Automated testing using dotnet test
2. Docker image build using the local Dockerfile
3. Detection and termination of containers using ports 5000 or 5001
4. Removal of any existing container with the same name
5. Launching a new container with HTTPS and port bindings
6. Opening the application in the browser

## How to Run

From the root directory:

1. Open PowerShell
2. Run:

   .\Deploy.ps1

This will execute tests, build the image, clean up containers, and start a new one.

## API Endpoints

- http://localhost:5000/time
- https://localhost:5001/time

The HTTPS endpoint uses the mkcert certificate to simulate secure local deployment.

## Troubleshooting

If you see a "Not Secure" message:

- Chrome trusts mkcert by default; Edge may require manual certificate import
- Clear browser cache or try a private window
- Ensure Docker is running and ports 5000/5001 are not in use

If container fails:

- Use docker ps to inspect running containers
- Use docker rm -f <container_id> to remove any that conflict

If only partial HTTPS security is shown:

- Check browser developer tools for mixed content
- Ensure all traffic is routed over HTTPS

## CI/CD Ready

This setup is designed for local simulation but can be extended into CI/CD pipelines:

- Use GitHub Actions or Azure DevOps to replace Deploy.ps1 steps
- Use Docker registries for image publishing
- Use cloud-native certificate management (e.g. Azure Key Vault, AWS ACM)

## Summary

This solution provides:

- Secure local Docker deployment using HTTPS
- Automated test-and-deploy workflow via PowerShell
- Best practices for container security (non-root user)
- Clean modular code for API and test layers

This is a production-grade foundation suitable for real-world CI/CD and secure web API development.
