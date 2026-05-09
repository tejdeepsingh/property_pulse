param(
  [string]$ImageName = "property-pulse",
  [string]$ContainerName = "property-pulse",
  [string]$HostPort = "3000",
  [string]$NextPublicDomain,
  [string]$NextPublicApiDomain,
  [string]$MongoDbUri,
  [string]$GoogleClientId,
  [string]$GoogleClientSecret,
  [string]$NextAuthUrl,
  [string]$NextAuthUrlInternal,
  [string]$NextAuthSecret,
  [string]$CloudinaryCloudName,
  [string]$CloudinaryApiKey,
  [string]$CloudinaryApiSecret,
  [string]$NextPublicGoogleGeocodingApiKey,
  [string]$NextPublicMapboxToken
)

$ErrorActionPreference = "Stop"

function Import-DotEnv {
  param([string]$Path)

  $values = @{}

  if (-not (Test-Path -LiteralPath $Path)) {
    return $values
  }

  Get-Content -LiteralPath $Path | ForEach-Object {
    $line = $_.Trim()

    if (-not $line -or $line.StartsWith("#")) {
      return
    }

    $parts = $line -split "=", 2
    if ($parts.Count -ne 2) {
      return
    }

    $key = $parts[0].Trim()
    $value = $parts[1].Trim().Trim("'`"")
    $values[$key] = $value
  }

  return $values
}

function Resolve-EnvValue {
  param(
    [string]$ExplicitValue,
    [hashtable]$DotEnv,
    [string]$Key
  )

  if ($null -ne $ExplicitValue -and $ExplicitValue -ne "") {
    return $ExplicitValue
  }

  if ($DotEnv.ContainsKey($Key) -and $DotEnv[$Key] -ne "") {
    return $DotEnv[$Key]
  }

  return $null
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repoRoot

$dotEnv = Import-DotEnv -Path (Join-Path $repoRoot ".env")

$envMap = [ordered]@{
  NEXT_PUBLIC_DOMAIN = Resolve-EnvValue -ExplicitValue $NextPublicDomain -DotEnv $dotEnv -Key "NEXT_PUBLIC_DOMAIN"
  NEXT_PUBLIC_API_DOMAIN = Resolve-EnvValue -ExplicitValue $NextPublicApiDomain -DotEnv $dotEnv -Key "NEXT_PUBLIC_API_DOMAIN"
  MONGODB_URI = Resolve-EnvValue -ExplicitValue $MongoDbUri -DotEnv $dotEnv -Key "MONGODB_URI"
  GOOGLE_CLIENT_ID = Resolve-EnvValue -ExplicitValue $GoogleClientId -DotEnv $dotEnv -Key "GOOGLE_CLIENT_ID"
  GOOGLE_CLIENT_SECRET = Resolve-EnvValue -ExplicitValue $GoogleClientSecret -DotEnv $dotEnv -Key "GOOGLE_CLIENT_SECRET"
  NEXTAUTH_URL = Resolve-EnvValue -ExplicitValue $NextAuthUrl -DotEnv $dotEnv -Key "NEXTAUTH_URL"
  NEXTAUTH_URL_INTERNAL = Resolve-EnvValue -ExplicitValue $NextAuthUrlInternal -DotEnv $dotEnv -Key "NEXTAUTH_URL_INTERNAL"
  NEXTAUTH_SECRET = Resolve-EnvValue -ExplicitValue $NextAuthSecret -DotEnv $dotEnv -Key "NEXTAUTH_SECRET"
  CLOUDINARY_CLOUD_NAME = Resolve-EnvValue -ExplicitValue $CloudinaryCloudName -DotEnv $dotEnv -Key "CLOUDINARY_CLOUD_NAME"
  CLOUDINARY_API_KEY = Resolve-EnvValue -ExplicitValue $CloudinaryApiKey -DotEnv $dotEnv -Key "CLOUDINARY_API_KEY"
  CLOUDINARY_API_SECRET = Resolve-EnvValue -ExplicitValue $CloudinaryApiSecret -DotEnv $dotEnv -Key "CLOUDINARY_API_SECRET"
  NEXT_PUBLIC_GOOGLE_GEOCODING_API_KEY = Resolve-EnvValue -ExplicitValue $NextPublicGoogleGeocodingApiKey -DotEnv $dotEnv -Key "NEXT_PUBLIC_GOOGLE_GEOCODING_API_KEY"
  NEXT_PUBLIC_MAPBOX_TOKEN = Resolve-EnvValue -ExplicitValue $NextPublicMapboxToken -DotEnv $dotEnv -Key "NEXT_PUBLIC_MAPBOX_TOKEN"
}

$requiredKeys = @(
  "NEXT_PUBLIC_DOMAIN",
  "NEXT_PUBLIC_API_DOMAIN",
  "MONGODB_URI",
  "GOOGLE_CLIENT_ID",
  "GOOGLE_CLIENT_SECRET",
  "NEXTAUTH_URL",
  "NEXTAUTH_SECRET",
  "CLOUDINARY_CLOUD_NAME",
  "CLOUDINARY_API_KEY",
  "CLOUDINARY_API_SECRET"
)

$missingKeys = $requiredKeys | Where-Object { -not $envMap[$_] }
if ($missingKeys.Count -gt 0) {
  throw "Missing required environment values: $($missingKeys -join ', ')"
}

$buildArgs = @(
  "build",
  "-t", $ImageName,
  "--build-arg", "NEXT_PUBLIC_DOMAIN=$($envMap.NEXT_PUBLIC_DOMAIN)",
  "--build-arg", "NEXT_PUBLIC_API_DOMAIN=$($envMap.NEXT_PUBLIC_API_DOMAIN)",
  "--build-arg", "NEXT_PUBLIC_GOOGLE_GEOCODING_API_KEY=$($envMap.NEXT_PUBLIC_GOOGLE_GEOCODING_API_KEY)",
  "--build-arg", "NEXT_PUBLIC_MAPBOX_TOKEN=$($envMap.NEXT_PUBLIC_MAPBOX_TOKEN)",
  "--build-arg", "MONGODB_URI=$($envMap.MONGODB_URI)",
  "--build-arg", "GOOGLE_CLIENT_ID=$($envMap.GOOGLE_CLIENT_ID)",
  "--build-arg", "GOOGLE_CLIENT_SECRET=$($envMap.GOOGLE_CLIENT_SECRET)",
  "--build-arg", "NEXTAUTH_URL=$($envMap.NEXTAUTH_URL)",
  "--build-arg", "NEXTAUTH_URL_INTERNAL=$($envMap.NEXTAUTH_URL_INTERNAL)",
  "--build-arg", "NEXTAUTH_SECRET=$($envMap.NEXTAUTH_SECRET)",
  "--build-arg", "CLOUDINARY_CLOUD_NAME=$($envMap.CLOUDINARY_CLOUD_NAME)",
  "--build-arg", "CLOUDINARY_API_KEY=$($envMap.CLOUDINARY_API_KEY)",
  "--build-arg", "CLOUDINARY_API_SECRET=$($envMap.CLOUDINARY_API_SECRET)",
  "."
)

Write-Host "Building Docker image $ImageName"
& docker @buildArgs
if ($LASTEXITCODE -ne 0) {
  throw "Docker build failed."
}

$existingContainer = docker ps -aq -f "name=^${ContainerName}$"
if ($existingContainer) {
  Write-Host "Removing existing container $ContainerName"
  docker rm -f $ContainerName | Out-Null
}

$runArgs = @(
  "run",
  "-d",
  "--name", $ContainerName,
  "-p", "${HostPort}:3000"
)

foreach ($entry in $envMap.GetEnumerator()) {
  if ($null -ne $entry.Value -and $entry.Value -ne "") {
    $runArgs += "--env"
    $runArgs += "$($entry.Key)=$($entry.Value)"
  }
}

$runArgs += $ImageName

Write-Host "Starting Docker container $ContainerName on port $HostPort"
& docker @runArgs
if ($LASTEXITCODE -ne 0) {
  throw "Docker run failed."
}

Write-Host "Deployment complete."
