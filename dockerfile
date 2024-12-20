FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env
WORKDIR /Appen

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /Appen
COPY --from=build-env /Appen/out .
ENTRYPOINT ["dotnet", "Appen.dll"]