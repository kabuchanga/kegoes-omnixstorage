# OmnixStorage SDK - Client Libraries

This directory contains pre-built SDK packages for integrating with OmnixStorage from your applications.

## Available SDKs

### 1. .NET/C# SDK

- **Package File**: `releases/OmnixStorage.1.0.0.nupkg`
- **Package Name**: `OmnixStorage`
- **Version**: 1.0.0
- **Source**: `omnix-storage-dotnet/`

**Installation Options**:

```bash
# Option 1: From GitHub Releases (Recommended)
dotnet add package OmnixStorage --source "https://github.com/kabuchanga/kegoes-omnixstorage/releases/download/v1.0.0/OmnixStorage.1.0.0.nupkg"

# Option 2: From NuGet.org (when published)
dotnet add package OmnixStorage

# Option 3: From local file
dotnet add package "releases/OmnixStorage.1.0.0.nupkg"
```

Or add to `.csproj`:
```xml
<ItemGroup>
  <PackageReference Include="OmnixStorage" Version="1.0.0">
    <Source>https://github.com/kabuchanga/kegoes-omnixstorage/releases/download/v1.0.0/</Source>
  </PackageReference>
</ItemGroup>
```

**Quick Start**:
```csharp
using OmnixStorage;

var client = new OmnixStorageClientBuilder()
    .WithEndpoint("localhost:9000")
    .WithCredentials("admin", "omnix-secret-2026")
    .WithSSL(false)
    .Build();

// Create bucket
await client.MakeBucketAsync("my-bucket");

// Upload file
using (var fileStream = new FileStream("file.txt", FileMode.Open))
{
    await client.PutObjectAsync("my-bucket", "file.txt", fileStream);
}

// List objects
var objects = await client.ListObjectsAsync("my-bucket");
```

**Features**:
- Full S3 API compatibility
- Fluent builder pattern
- Async/await support
- No external dependencies (uses .NET standard library)
- JWT authentication with automatic token caching
- Presigned URL generation

**Documentation**: See `omnix-storage-dotnet/README.md`

---

### 2. Python SDK

- **Package File**: `releases/omnix-storage-1.0.0.tar.gz`
- **Package Name**: `omnix-storage`
- **Version**: 1.0.0
- **Source**: `omnix-storage-py/`

**Installation Options**:

```bash
# Option 1: From GitHub Releases (Recommended)
pip install https://github.com/kabuchanga/kegoes-omnixstorage/releases/download/v1.0.0/omnix-storage-1.0.0.tar.gz

# Option 2: From PyPI (when published)
pip install omnix-storage

# Option 3: From local file
pip install releases/omnix-storage-1.0.0.tar.gz
```

Or add to `requirements.txt`:
```
omnix-storage @ https://github.com/kabuchanga/kegoes-omnixstorage/releases/download/v1.0.0/omnix-storage-1.0.0.tar.gz
```

**Quick Start**:
```python
import asyncio
from omnixstorage import OmnixClient

async def main():
    client = OmnixClient(
        endpoint="localhost:9000",
        access_key="admin",
        secret_key="omnix-secret-2026"
    )
    
    # Create bucket
    await client.make_bucket("my-bucket")
    
    # Upload file
    with open("file.txt", "rb") as f:
        await client.put_object("my-bucket", "file.txt", f)
    
    # List objects
    objects = await client.list_objects("my-bucket")

asyncio.run(main())
```

**Features**:
- Full S3 API compatibility
- Async/await support with asyncio
- Connection pooling
- Automatic retries
- JWT authentication
- Type hints for IDE support

**Documentation**: See `omnix-storage-py/README.md`

**Requirements**:
- Python 3.8+
- httpx>=0.24.0
- python-dateutil>=2.8.2

---

## Publishing to Package Repositories

### Publishing .NET SDK to NuGet

```bash
cd omnix-storage-dotnet
dotnet nuget push releases/OmnixStorage.1.0.0.nupkg --api-key <your-nuget-key> --source https://api.nuget.org/v3/index.json
```

### Publishing Python SDK to PyPI

```bash
cd omnix-storage-py

# Install build dependencies
pip install build twine

# Build package
python -m build

# Upload to PyPI
twine upload dist/omnix-storage-1.0.0.tar.gz
```

---

## SDK Architecture

Both SDKs implement the same interfaces for consistency:

```
OmnixStorageClient
├── Bucket Operations
│   ├── MakeBucket()
│   ├── ListBuckets()
│   └── DeleteBucket()
├── Object Operations
│   ├── PutObject()
│   ├── GetObject()
│   ├── DeleteObject()
│   └── ListObjects()
├── Presigned URLs
│   └── GetPresignedUrl()
├── Vector Search
│   ├── IndexVector()
│   └── SearchVectors()
└── Admin APIs
    ├── GetBucketStats()
    ├── CreateUser()
    └── SetBucketPolicy()
```

---

## Version History

| Version | Release Date | Status | Notes |
|---------|--------------|--------|-------|
| 1.0.0   | 2026-02-08   | Stable | Initial release for single-node OmnixStorage |

---

## Support

- **Issues & Questions**: [GitHub Issues](https://github.com/kabuchanga/kegoes-omnixstorage/issues)
- **Examples**: See `omnix-storage-dotnet/examples/` and `omnix-storage-py/examples/`
- **API Documentation**: Referenced in main README.md

---

## License

Both SDKs are licensed under Apache 2.0 License.
