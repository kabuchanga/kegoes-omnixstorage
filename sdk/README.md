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
- AWS Signature V4 authentication (default, 2.4x faster)
- Dual authentication modes (AWS SigV4 and JWT)
- Fluent builder pattern
- Async/await support with nullable reference types
- No external dependencies (uses .NET standard library)
- Multipart upload with resume capability
- Presigned URL generation
- Comprehensive error handling

**Common Operations**:

```csharp
// Create bucket
bool exists = await client.BucketExistsAsync("my-bucket");
if (!exists) {
    await client.MakeBucketAsync("my-bucket");
}

// Upload with metadata
var metadata = new Dictionary<string, string> { ["author"] = "John Doe" };
using (var fs = new FileStream("document.pdf", FileMode.Open)) {
    var result = await client.PutObjectAsync(
        bucketName: "my-bucket",
        objectName: "docs/report.pdf",
        data: fs,
        contentType: "application/pdf",
        metadata: metadata
    );
}

// Download file
using (var output = new FileStream("downloaded.jpg", FileMode.Create")) {
    var metadata = await client.GetObjectAsync("my-bucket", "photos/vacation.jpg", output);
}

// List objects with pagination
var result = await client.ListObjectsAsync("my-bucket", prefix: "photos/", maxKeys: 100);
foreach (var obj in result.Objects) {
    Console.WriteLine($"{obj.Name} - {obj.Size} bytes");
}

// Presigned URLs (valid for 1 hour)
string downloadUrl = await client.PresignedGetUrlAsync("my-bucket", "photo.jpg", expiresInSeconds: 3600);
string uploadUrl = await client.PresignedPutUrlAsync("my-bucket", "upload.jpg", expiresInSeconds: 3600);

// Multipart upload for large files
var manager = new MultipartUploadManager(
    client: client,
    bucketName: "my-bucket",
    objectName: "large-file.zip",
    partSize: 10 * 1024 * 1024  // 10MB parts
);
string etag = await manager.UploadFileAsync("large-file.zip");
```

**Error Handling**:

```csharp
using OmnixStorage.Exceptions;

try {
    await client.GetObjectAsync("my-bucket", "missing.txt", output);
}
catch (ObjectNotFoundException) {
    Console.WriteLine("Object doesn't exist");
}
catch (BucketNotFoundException) {
    Console.WriteLine("Bucket doesn't exist");
}
catch (AuthenticationException) {
    Console.WriteLine("Invalid credentials");
}
```

**Authentication Modes**:
- **AWS SigV4** (default): Best for S3 operations, 2.4x faster, no token round-trip
- **JWT Mode**: For admin operations, add `.UseJwtAuthentication()` to builder

**Additional Documentation**: See `omnix-storage-dotnet/` directory for full README, examples, and API reference

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
- AWS Signature V4 authentication
- Async/await support with asyncio
- Connection pooling with HTTP keep-alive
- Automatic retry logic for transient failures
- Multipart upload with resume capability
- Session persistence for upload recovery
- Progress callbacks for operations
- Type hints for IDE support
- Comprehensive error handling

**Common Operations**:

```python
# Create bucket
if not await client.bucket_exists("my-bucket"):
    await client.make_bucket("my-bucket")

# Upload with metadata
with open("document.pdf", "rb") as f:
    result = await client.put_object(
        bucket_name="my-bucket",
        object_name="docs/report.pdf",
        data=f,
        content_type="application/pdf",
        metadata={"author": "John Doe", "version": "1.0"}
    )

# Download file
with open("downloaded.jpg", "wb") as f:
    metadata = await client.get_object(
        bucket_name="my-bucket",
        object_name="photos/vacation.jpg",
        output=f
    )

# List objects with pagination
result = await client.list_objects(
    bucket_name="my-bucket",
    prefix="photos/",
    max_keys=100
)
for obj in result.objects:
    print(f"{obj.name} - {obj.size} bytes")

# Handle pagination
if result.is_truncated:
    next_result = await client.list_objects(
        bucket_name="my-bucket",
        continuation_token=result.next_continuation_token
    )

# Presigned URLs (valid for 1 hour)
download_url = await client.presigned_get_url("my-bucket", "photo.jpg", expires=3600)
upload_url = await client.presigned_put_url("my-bucket", "upload.jpg", expires=3600)

# Multipart upload for large files
from omnixstorage.multipart import MultipartUploadManager

manager = MultipartUploadManager(
    client=client,
    bucket_name="my-bucket",
    object_name="large-file.zip",
    part_size=10 * 1024 * 1024  # 10MB parts
)

def progress(uploaded, total):
    print(f"Progress: {(uploaded/total)*100:.1f}%")

etag = await manager.upload_file("large-file.zip", progress_callback=progress)

# Always close client
await client.close()
```

**Error Handling**:

```python
from omnixstorage.error import (
    BucketNotFoundException,
    ObjectNotFoundException,
    AuthenticationException
)

try:
    await client.get_object("my-bucket", "missing.txt", output=...)
except ObjectNotFoundException:
    print("Object doesn't exist")
except BucketNotFoundException:
    print("Bucket doesn't exist")
except AuthenticationException:
    print("Invalid credentials")
```

**Complete Example**:

```python
import asyncio
from omnixstorage import OmnixClient

async def main():
    client = OmnixClient(
        endpoint="localhost:9000",
        access_key="minioadmin",
        secret_key="minioadmin",
        use_ssl=False
    )
    
    try:
        # Create bucket
        if not await client.bucket_exists("quickstart-bucket"):
            await client.make_bucket("quickstart-bucket")
        
        # Upload file
        from io import BytesIO
        result = await client.put_object(
            bucket_name="quickstart-bucket",
            object_name="test.txt",
            data=BytesIO(b"Hello, OmnixStorage!"),
            content_type="text/plain"
        )
        print(f"✓ Uploaded, ETag: {result.etag}")
        
        # List objects
        result = await client.list_objects("quickstart-bucket")
        print(f"✓ Found {len(result.objects)} objects")
        
        # Cleanup
        await client.remove_object("quickstart-bucket", "test.txt")
        await client.remove_bucket("quickstart-bucket")
    finally:
        await client.close()

if __name__ == "__main__":
    asyncio.run(main())
```

**Additional Documentation**: See `omnix-storage-py/` directory for full README, examples, and API reference

---

## Testing & Quality

Both SDKs have comprehensive test coverage:

### .NET SDK Tests
- ✅ **32/32 tests passing** (100%)
- Domain layer tests
- Application layer tests  
- Infrastructure layer tests
- Integration tests
- Chaos testing suite

```bash
cd omnix-storage-dotnet
dotnet test OmnixStorage.sln -c Release
```

### Python SDK Tests
- ✅ **148/148 tests passing** (100%)
- Unit tests for all modules
- Multipart upload tests
- Concurrent operation tests
- Error handling tests
- MD5 integrity tests

```bash
cd omnix-storage-py
pytest tests/ -v
```

---

## Publishing to Package Repositories

### Publishing .NET SDK to NuGet

```bash
cd omnix-storage-dotnet

# Pack the SDK
dotnet pack src/OmnixStorage/OmnixStorage.csproj -c Release

# Publish to NuGet
dotnet nuget push bin/Release/OmnixStorage.1.0.0.nupkg \
  --api-key <your-nuget-key> \
  --source https://api.nuget.org/v3/index.json
```├── BucketExists()
│   └── RemoveBucket()
├── Object Operations
│   ├── PutObject()
│   ├── GetObject()
│   ├── StatObject()
│   ├── RemoveObject()
│   └── ListObjects() (with pagination)
├── Multipart Upload
│   ├── InitiateUpload()
│   ├── UploadPart()
│   ├── CompleteUpload()
│   ├── AbortUpload()
│   └── ResumeUpload() (session-based)
├── Presigned URLs
│   ├── PresignedGetUrl()
│   └── PresignedPutUrl()
└── Health & Management
    └── Health()
```

### Build Quality

Both SDKs are production-ready with:
- ✅ **Zero build warnings** (cleaned up all compiler warnings)
- ✅ **100% test pass rate** (.NET: 32/32, Python: 148/148)
- ✅ **Full nullable reference type support** (.NET)
- ✅ **Complete type hints** (Python)
- ✅ **PEP 621 compliance** (Python packaging)
- ✅ **XML documentation** for all public APIs (.NET)
- ✅ **Comprehensive docstrings** (Python)

---

## Publishing to Package Repositories

### Publishing .NET SDK to NuGet

```bash
cd omnix-storage-dotnet

# Pack the SDK
dotnet pack src/OmnixStorage/OmnixStorage.csproj -c Release

# Publish to NuGet
dotnet nuget push bin/Release/OmnixStorage.1.0.0.nupkg \
  --api-key <your-nuget-key> \
  --source https://api.nuget.org/v3/index.json
```

**Authenticating to NuGet**:
1. Create API key at https://www.nuget.org/account/apikeys
2. Store securely (don't commit to source control)
3. For CI/CD: Use secret environment variables

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

**Authenticating to PyPI**:

Create `~/.pypirc`:
```ini
[pypi]
username = __token__
password = pypi-<your-token-here>
```

Or use environment variable:
```bash
export TWINE_PASSWORD=pypi-<your-token-here>
twine upload dist/*
```

---

## SDK Architecture

Both SDKs implement the same interfaces for consistency:

```
OmnixStorageClient
├── Bucket Operations
│   ├── MakeBucket()
│   ├── ListBuckets()
│   ├── BucketExists()
│   └── RemoveBucket()
├── Object Operations
│   ├── PutObject()
│   ├── GetObject()
│   ├── StatObject()
│   ├── RemoveObject()
│   └── ListObjects() (with pagination)
├── Multipart Upload
│   ├── InitiateUpload()
│   ├── UploadPart()
│   ├── CompleteUpload()
│   ├── AbortUpload()
│   └── ResumeUpload() (session-based)
├── Presigned URLs
│   ├── PresignedGetUrl()
│   └── PresignedPutUrl()
└── Health & Management
    └── Health()
```

---

## Troubleshooting

### Common Issues

**Authentication Errors (401)**:
- For .NET: Verify using AWS SigV4 mode (default) for S3 operations
- For Python: Ensure correct `access_key` and `secret_key` format
- Check endpoint is reachable: `ping your-server.com`

**Connection Timeouts**:
- Verify firewall rules allow traffic on port 9000
- For large uploads, increase timeout: `.WithTimeout(TimeSpan.FromMinutes(10))` (.NET) or set longer request timeout (Python)
- Use multipart upload for files > 100MB

**SSL Certificate Errors**:
- For development: Set `WithSSL(false)` (.NET) or `use_ssl=False` (Python)
- For production: Ensure valid SSL certificate installed
- For self-signed certs: May need to disable cert validation (not recommended for production)

**Bucket/Object Not Found (404)**:
- Verify bucket exists: `BucketExistsAsync()` or `bucket_exists()`
- Check object name spelling and case sensitivity
- Ensure bucket name follows S3 naming rules (lowercase, no special chars)

**File Upload Failures**:
- Ensure file isn't locked by another process
- Check disk space on server
- For large files, use multipart upload with retry logic
- Verify `content_type` is set correctly

**Memory Issues with Large Files**:
- Always use streaming operations (don't load entire file into memory)
- Use multipart upload for files > 5MB
- Set appropriate part size: 10-50MB typically optimal

**Import/Module Not Found (Python)**:
- Verify package installed: `pip show omnix-storage`
- Check Python version >= 3.8
- Ensure virtual environment activated

**Package Restore Failures (.NET)**:
- Clear NuGet cache: `dotnet nuget locals all --clear`
- Check network connectivity to NuGet.org
- Verify .NET SDK version >= 10.0

### Performance Tips

**For Optimal Performance**:
1. **Connection Pooling**: Both SDKs reuse connections automatically
2. **Multipart Uploads**: Files > 100MB should use multipart upload
3. **Concurrent Operations**: Use async/await for parallel uploads/downloads
4. **Part Size**: 10-50MB parts optimal for multipart uploads
5. **Region Selection**: Choose endpoint closest to your application
6. **Retry Logic**: Both SDKs have automatic retry with exponential backoff
7. **AWS SigV4**: Use default auth mode (.NET) - 2.4x faster than JWT

### Getting Help

**Before reporting an issue**:
1. Check if running latest SDK version
2. Review error message carefully
3. Try with minimal code example
4. Check server logs if accessible

**Report issues**:
- GitHub Issues: https://github.com/kabuchanga/kegoes-omnixstorage/issues
- Include: SDK version, error message, minimal reproduction code
- For connection issues: Include `curl` test to verify endpoint reachability

---

## Version History

| Version | Release Date | Status | Notes |
|---------|--------------|--------|-------|
| 1.0.0   | 2026-02-15   | Stable | Production release with comprehensive testing and documentation |

### Changelog - What's in v1.0.0

**Core Features**:
- Full S3-compatible API implementation
- AWS Signature V4 authentication (default)
- Multipart upload with resume capability
- Presigned URL generation
- Connection pooling and automatic retries
- Comprehensive error handling

**Quality Improvements**:
- All compiler warnings eliminated
- 180 total tests (32 .NET + 148 Python) - 100% passing
- Complete API documentation with examples
- Production-ready error handling
- Memory-efficient streaming operations

**Build Quality**:
- Zero build warnings (cleaned up all compiler warnings)
- 100% test pass rate (.NET: 32/32, Python: 148/148)
- Full nullable reference type support (.NET)
- Complete type hints (Python)
- PEP 621 compliance (Python packaging)
- XML documentation for all public APIs (.NET)
- Comprehensive docstrings (Python)

---

## Support & Additional Resources

- **Issues & Questions**: [GitHub Issues](https://github.com/kabuchanga/kegoes-omnixstorage/issues)
- **Working Examples**: 
  - .NET: `omnix-storage-dotnet/examples/` directory
  - Python: `omnix-storage-py/examples/` directory
- **Full Documentation**:
  - .NET: `omnix-storage-dotnet/README.md` and `docs/` folder
  - Python: `omnix-storage-py/README.md` and `docs/` folder
- **API References**: Complete API documentation in each SDK's docs folder
- **Community**: Contributions welcome! See CONTRIBUTING.md in each SDK directory

---

## License

Both SDKs are licensed under Apache 2.0 License.
