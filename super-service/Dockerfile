# Stage 1: Build using .NET 8 SDK Alpine image
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /app

# Copy source and test projects
COPY ./src ./src
COPY ./test ./test

# Restore and publish
WORKDIR /app/src
RUN dotnet restore
RUN dotnet publish -c Release -o /app/out

# Stage 2: Runtime image using .NET 8 ASP.NET Alpine
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
WORKDIR /app

# Create non-root user for security
RUN adduser -D appuser
USER appuser

# Copy published app from build stage
COPY --from=build /app/out ./ 

# Copy mkcert HTTPS development certificates
COPY https/localhost.pem /https/localhost.pem
COPY https/localhost-key.pem /https/localhost-key.pem

# Environment variables for Kestrel to use HTTPS
ENV ASPNETCORE_Kestrel__Certificates__Default__Path="/https/localhost.pem"
ENV ASPNETCORE_Kestrel__Certificates__Default__KeyPath="/https/localhost-key.pem"
ENV ASPNETCORE_URLS="https://+:5001;http://+:5000"

# Expose HTTP and HTTPS ports
EXPOSE 5000
EXPOSE 5001

# Start the application
ENTRYPOINT ["dotnet", "SuperService.dll"]