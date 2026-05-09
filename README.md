# Property Pulse

> A web application to help you find your next rental property.

live - https://property-pulse-vert.vercel.app/

## Docker

Build and run with Docker through `deploy.ps1`.

```powershell
.\deploy.ps1
```

The script reads `.env` by default and passes the values into Docker build and run. You can override any value directly:

```powershell
.\deploy.ps1 -HostPort 3001 -NextPublicDomain "http://localhost:3001" -NextPublicApiDomain "http://localhost:3001/api"
```
