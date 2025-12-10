# Phase 7 Complete: US5 - Bulk Content Import

**Date**: December 10, 2025  
**Tasks Completed**: T036-T038 (3 tasks)  
**Status**: ✅ All Phase 7 tasks complete

---

## Summary

Phase 7 implements a two-step bulk import workflow for admins to quickly populate speech content via audio file uploads and CSV data import.

### Features Delivered

#### 1. ImportService - Core Import Logic (T038)
**File**: `app/services/import_service.py`

**Features**:
- **Audio Upload Management**
  - In-memory session tracking (MVP approach)
  - Duplicate filename handling with automatic suffixes (_1, _2, etc.)
  - File validation (extensions, size limits)
  - MinIO storage integration
  - 24-hour session expiration

- **CSV Parsing & Validation**
  - Complete CSV validation before any records created (atomic)
  - Required columns: audio_filename, text, level
  - Optional columns: type, tags
  - Row-by-row validation with detailed error reporting
  - Duplicate filename detection within CSV
  - Audio file reference validation against upload session

- **Bulk Speech Creation**
  - Atomic transaction (all or nothing)
  - Tag auto-creation with category "imported"
  - Tag name-based lookup and reuse
  - Batch speech creation with tag associations

**Data Classes**:
- `UploadedFile` - Represents uploaded audio file with metadata
- `UploadSession` - Tracks files in a session with expiration
- `CSVValidationError` - Row-level validation error details
- `CreatedSpeech` - Successfully created speech record

**Key Methods**:
- `upload_audio_files()` - Upload multiple audio files, return session ID
- `import_csv()` - Parse and validate CSV, create speeches atomically
- `cleanup_expired_sessions()` - Remove sessions older than 24 hours

**Validation Rules**:
- Audio extensions: .mp3, .wav, .m4a
- Max file size: 10MB per file
- CSV required fields: audio_filename, text, level
- Level must be valid CEFR (A1, A2, B1, B2, C1)
- Type must be question or answer (default: answer)
- Audio filename must exist in upload session
- No duplicate audio filenames within CSV

#### 2. Audio Upload Endpoint (T036)
**File**: `app/api/v1/admin/imports.py`

**Endpoint**: `POST /api/v1/admin/import/audio`

**Request**:
- Content-Type: multipart/form-data
- Body: Multiple files (files parameter)
- File formats: MP3, WAV, M4A
- Max size: 10MB per file

**Response** (201 Created):
```json
{
  "upload_session_id": "session-uuid",
  "uploaded_files": [
    {
      "id": "file-uuid-1",
      "original_filename": "sentence_001.mp3",
      "storage_url": "https://minio.local:9000/.../uploads/session-uuid/sentence_001.mp3",
      "size_bytes": 45678
    }
  ]
}
```

**Features**:
- Multiple file upload in single request
- Automatic duplicate filename handling
- Storage in temporary uploads/ path
- Session ID generation for CSV import
- Comprehensive error messages

**Error Responses**:
- 400 Bad Request: Invalid file extension, file too large, no files provided
- 500 Internal Server Error: Storage upload failure

#### 3. CSV Import Endpoint (T037)
**File**: `app/api/v1/admin/imports.py`

**Endpoint**: `POST /api/v1/admin/import/csv`

**Request**:
- Content-Type: multipart/form-data
- Body:
  - file: CSV file
  - upload_session_id: Session ID from audio upload

**CSV Format**:
```csv
audio_filename,text,level,type,tags
sentence_001.mp3,"What is your name?",A1,question,"present_tense,basics"
sentence_002.mp3,"My name is John.",A1,answer,"present_tense,basics"
```

**Response** (200 OK):
```json
{
  "success_count": 2,
  "error_count": 1,
  "created_speeches": [
    {
      "row": 2,
      "speech_id": "uuid-1",
      "text": "What is your name?"
    }
  ],
  "errors": [
    {
      "row": 4,
      "error": "Audio file 'missing.mp3' not found in upload session"
    }
  ]
}
```

**Features**:
- Complete validation before any records created
- Row-by-row error reporting with line numbers
- Tag auto-creation with category "imported"
- Atomic transaction (all or nothing if no errors)
- Audio file reference validation
- Detailed validation error messages

**Error Responses**:
- 400 Bad Request: Invalid CSV format, session not found/expired, missing required columns
- 422 Unprocessable Entity: Validation errors (returned with error details in response)

---

## File Structure

```
apps/backend/
├── app/
│   ├── api/v1/admin/
│   │   ├── __init__.py        # Added imports module
│   │   └── imports.py         # T036-T037: Import endpoints
│   ├── services/
│   │   └── import_service.py  # T038: ImportService
│   └── main.py                # Mounted imports router
└── tasks.md                   # Marked T036-T038 complete
```

---

## Two-Step Import Workflow

### Step 1: Upload Audio Files

```bash
curl -X POST http://localhost:8000/api/v1/admin/import/audio \
  -F "files=@audio1.mp3" \
  -F "files=@audio2.mp3" \
  -F "files=@audio3.mp3"
```

**Response**:
```json
{
  "upload_session_id": "abc-123",
  "uploaded_files": [...]
}
```

### Step 2: Upload CSV

```bash
curl -X POST http://localhost:8000/api/v1/admin/import/csv \
  -F "file=@speeches.csv" \
  -F "upload_session_id=abc-123"
```

**Response**:
```json
{
  "success_count": 3,
  "error_count": 0,
  "created_speeches": [...],
  "errors": []
}
```

---

## CSV Import Examples

### Valid CSV

```csv
audio_filename,text,level,type,tags
greeting_001.mp3,"Hello, how are you?",A1,question,"greetings,daily_life"
greeting_002.mp3,"I'm fine, thank you.",A1,answer,"greetings,daily_life"
intro_001.mp3,"My name is Sarah.",A1,answer,"introductions,present_simple"
```

**Result**: All 3 speeches created successfully

### CSV with Errors

```csv
audio_filename,text,level,type,tags
valid_001.mp3,"Hello world",A1,answer,"basics"
missing_audio.mp3,"Missing file",A1,answer,"test"
valid_002.mp3,"Another speech",D1,answer,"test"
valid_003.mp3,"",A1,answer,"test"
```

**Result**:
- Row 2: Error - "Audio file 'missing_audio.mp3' not found in upload session"
- Row 3: Error - "Invalid level 'D1'. Must be one of: A1, A2, B1, B2, C1"
- Row 4: Error - "Missing required field: text"
- 0 speeches created (atomic - all or nothing)

---

## Data Model Integration

### Tag Auto-Creation

When CSV contains tags that don't exist:
1. Service checks if tag exists by name
2. If not found, creates new tag with category "imported"
3. Associates tag with speech

Example:
```csv
tags
"present_simple,daily_life,new_tag"
```

If "new_tag" doesn't exist:
- Created with name="new_tag", category="imported"
- Associated with the speech

### Speech Creation

Each valid CSV row creates:
1. Speech record with:
   - audio_url: From upload session file mapping
   - text: From CSV text column
   - level: Validated CEFR level enum
   - type: question or answer (default: answer)
   - created_at, updated_at: Auto-generated timestamps

2. Tag associations:
   - Parse comma-separated tag names
   - Get or create each tag
   - Link via speech_tags join table

---

## Validation Details

### Audio File Validation

**Extensions**: .mp3, .wav, .m4a (case-insensitive)

**Size Limit**: 10MB per file

**Duplicate Handling**:
- Original: `audio.mp3` → `uploads/session-id/audio.mp3`
- Duplicate 1: `audio.mp3` → `uploads/session-id/audio_1.mp3`
- Duplicate 2: `audio.mp3` → `uploads/session-id/audio_2.mp3`

### CSV Validation

**Required Columns**: audio_filename, text, level

**Row Validation**:
1. audio_filename: Not empty, exists in upload session, unique within CSV
2. text: Not empty
3. level: One of A1, A2, B1, B2, C1 (case-insensitive)
4. type: One of question, answer (case-insensitive, default: answer)
5. tags: Optional, comma-separated, trimmed

**Atomic Import**:
- If ANY row has validation errors, NO speeches are created
- All validation errors reported with row numbers
- Transaction rolled back on any database error

---

## Session Management

### Upload Sessions

**Storage**: In-memory dictionary (MVP)
- Future enhancement: Redis for distributed systems

**Lifecycle**:
1. Created: When audio files uploaded (POST /admin/import/audio)
2. Active: Referenced during CSV import (POST /admin/import/csv)
3. Expired: After 24 hours of creation
4. Cleanup: Manual via `ImportService.cleanup_expired_sessions()`

**Session Data**:
- session_id: UUID
- created_at: Timestamp
- files: Dictionary of original_filename → UploadedFile

### Expiration Handling

Sessions expire after 24 hours:
- `UploadSession.is_expired()` checks age
- Expired sessions rejected during CSV import
- Cleanup method removes expired sessions from memory

**Cleanup Example**:
```python
from app.services.import_service import ImportService

# Remove sessions older than 24 hours
removed_count = ImportService.cleanup_expired_sessions()
print(f"Removed {removed_count} expired sessions")
```

---

## Error Handling

### Audio Upload Errors

**Invalid Extension**:
```json
{
  "detail": "Invalid file extension '.txt'. Allowed: .mp3, .wav, .m4a"
}
```

**File Too Large**:
```json
{
  "detail": "File 'large_audio.mp3' exceeds max size of 10MB"
}
```

**No Files**:
```json
{
  "detail": "No files provided"
}
```

### CSV Import Errors

**Session Not Found**:
```json
{
  "detail": "Upload session 'invalid-uuid' not found"
}
```

**Session Expired**:
```json
{
  "detail": "Upload session 'old-uuid' has expired"
}
```

**Missing Required Columns**:
```json
{
  "detail": "CSV missing required columns. Required: {'audio_filename', 'text', 'level'}"
}
```

**Validation Errors**:
```json
{
  "success_count": 0,
  "error_count": 2,
  "created_speeches": [],
  "errors": [
    {"row": 2, "error": "Audio file 'missing.mp3' not found in upload session"},
    {"row": 3, "error": "Invalid level 'D1'. Must be one of: A1, A2, B1, B2, C1"}
  ]
}
```

---

## Performance Considerations

### Batch Upload

**Audio Files**:
- Multiple files uploaded in single HTTP request
- Sequential storage uploads (MinIO client limitation)
- Future: Parallel uploads with asyncio

**CSV Import**:
- Parse entire CSV in memory (reasonable for typical imports)
- Bulk speech creation in single transaction
- Tag lookups batched per unique tag name

### Memory Usage

**In-Memory Sessions**:
- Each session stores file metadata only (not content)
- Typical session: ~1KB per file
- 1000 sessions × 100 files = ~100MB memory
- Acceptable for MVP, move to Redis for scale

**CSV Parsing**:
- Entire CSV loaded into memory
- Typical CSV: 1000 rows × 200 bytes = 200KB
- Large imports (10K rows) = 2MB
- Acceptable for target use case

---

## Integration Notes

### Dependencies on Previous Phases

- **Phase 2**: Uses Speech, Tag models and speech_tags join table
- **Phase 4**: Uses StorageService for MinIO uploads
- **Phase 6**: Extends admin API with import endpoints

### Storage Path Structure

**Temporary Uploads**:
```
/speeches/uploads/{session_id}/{filename}
```

**Permanent Storage** (from Phase 4):
```
/speeches/{filename}
```

Note: Current implementation stores directly to permanent path. Future enhancement: Move from uploads/ to permanent path after successful CSV import.

---

## Testing Checklist

### Manual Testing

- [ ] Upload single audio file succeeds
- [ ] Upload multiple audio files succeeds
- [ ] Duplicate audio filenames get suffixes
- [ ] Invalid file extension rejected (400)
- [ ] File exceeding 10MB rejected (400)
- [ ] CSV import with valid data creates speeches
- [ ] CSV with invalid session ID fails (400)
- [ ] CSV with expired session fails (400)
- [ ] CSV with missing columns fails (400)
- [ ] CSV with validation errors returns detailed errors
- [ ] CSV with invalid audio filename fails (row-level error)
- [ ] CSV with invalid level fails (row-level error)
- [ ] CSV with empty text fails (row-level error)
- [ ] CSV with duplicate audio filenames fails (row-level error)
- [ ] Tags auto-created if missing
- [ ] Tags reused if already exist
- [ ] All speeches created in transaction (atomic)
- [ ] No speeches created if any validation errors

### API Testing

```bash
# Test audio upload
curl -X POST http://localhost:8000/api/v1/admin/import/audio \
  -F "files=@test1.mp3" \
  -F "files=@test2.mp3"

# Test CSV import (valid)
curl -X POST http://localhost:8000/api/v1/admin/import/csv \
  -F "file=@valid.csv" \
  -F "upload_session_id=<session-id>"

# Test CSV import (invalid session)
curl -X POST http://localhost:8000/api/v1/admin/import/csv \
  -F "file=@valid.csv" \
  -F "upload_session_id=invalid-uuid"

# Test CSV import (validation errors)
curl -X POST http://localhost:8000/api/v1/admin/import/csv \
  -F "file=@invalid.csv" \
  -F "upload_session_id=<session-id>"
```

---

## Known Limitations (MVP Scope)

1. **In-Memory Session Storage**: Sessions stored in application memory
   - Limitation: Lost on server restart, not suitable for multi-instance deployment
   - Future: Move to Redis for persistence and distributed access

2. **No Session Cleanup Automation**: Manual cleanup required
   - Limitation: Expired sessions accumulate in memory
   - Future: Background task for automatic cleanup

3. **Sequential Audio Uploads**: Files uploaded one at a time
   - Limitation: Slower for large batches
   - Future: Parallel uploads with asyncio

4. **No Permanent Path Migration**: Audio stays in uploads/ path
   - Limitation: Inconsistent with direct uploads
   - Future: Move files to /speeches/ path after successful import

5. **No Progress Tracking**: No status updates during large imports
   - Limitation: Client waits for entire import to complete
   - Future: WebSocket progress updates

6. **No Partial Import**: All or nothing approach
   - Limitation: One error prevents all imports
   - Future: Option to import valid rows, skip errors

---

## Progress Summary

**Phase 7 Complete**: 3/3 tasks ✅

**Overall Progress**: 40/51 tasks (78%)

**Completed Phases**:
- ✅ Phase 1: Setup & Infrastructure (5/5)
- ✅ Phase 2: Foundation Data Layer (6/6)
- ✅ Phase 3: US1 - Authentication (5/5)
- ✅ Phase 4: US2 - Game Play (11/11)
- ✅ Phase 5: US3 - History & Profile (5/5)
- ✅ Phase 6: US4 - Admin Panel (5/5)
- ✅ Phase 7: US5 - Content Import (3/3)

**Remaining Phase**:
- Phase 8: Testing & Polish (11 tasks)

---

## Next Steps

**Phase 8: Testing & Polish**
- T039: Redis caching decorator
- T040: Rate limiting with SlowAPI
- T041: Structured logging with structlog
- T042: Prometheus metrics instrumentation
- T043-T047: Comprehensive testing (unit, integration, E2E)
- T048: Security scans (Bandit, Safety)
- T049: Production Dockerfile
- T050: Deployment configuration
- T051: API documentation

Ready to proceed with Phase 8 (Testing & Polish) - the final phase! 🚀
