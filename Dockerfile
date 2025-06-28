# Stage 1: Build the app
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build
WORKDIR /app

# Copy everything
COPY ./src ./src
COPY ./test ./test

# Restore dependencies
WORKDIR /app/src
RUN dotnet restore

# Build and publish the app
RUN dotnet publish -c Release -o /app/publish

# Stage 2: Run the app
FROM mcr.microsoft.com/dotnet/aspnet:3.1 AS runtime
WORKDIR /app
COPY --from=build /app/publish .

# Expose port
EXPOSE 80

# Start the app
ENTRYPOINT ["dotnet", "SuperService.dll"]
