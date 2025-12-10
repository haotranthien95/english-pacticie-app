"""MinIO storage service for audio file management."""
import io
import mimetypes
from typing import Optional, BinaryIO
from urllib.parse import quote

import boto3
from botocore.client import Config
from botocore.exceptions import ClientError

from app.config import settings


class StorageError(Exception):
    """Raised when storage operations fail."""
    pass


class StorageService:
    """Service for managing audio files in MinIO/S3."""
    
    def __init__(self):
        """Initialize MinIO client."""
        self.client = boto3.client(
            "s3",
            endpoint_url=settings.s3_endpoint_url,
            aws_access_key_id=settings.s3_access_key,
            aws_secret_access_key=settings.s3_secret_key,
            config=Config(signature_version="s3v4"),
            use_ssl=settings.s3_use_ssl,
        )
        self.bucket_name = settings.s3_bucket_name
    
    def ensure_bucket_exists(self) -> None:
        """
        Ensure the audio bucket exists, create if not.
        
        Raises:
            StorageError: If bucket creation fails
        """
        try:
            self.client.head_bucket(Bucket=self.bucket_name)
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code")
            
            if error_code == "404":
                # Bucket doesn't exist, create it
                try:
                    self.client.create_bucket(Bucket=self.bucket_name)
                except ClientError as create_error:
                    raise StorageError(
                        f"Failed to create bucket: {str(create_error)}"
                    )
            else:
                raise StorageError(f"Failed to check bucket: {str(e)}")
    
    def upload_audio(
        self,
        file_data: BinaryIO,
        filename: str,
        content_type: Optional[str] = None,
    ) -> str:
        """
        Upload audio file to MinIO.
        
        Args:
            file_data: Binary file data stream
            filename: Desired filename in storage
            content_type: MIME type (auto-detected if None)
            
        Returns:
            Public URL of uploaded file
            
        Raises:
            StorageError: If upload fails
        """
        # Ensure bucket exists
        self.ensure_bucket_exists()
        
        # Auto-detect content type if not provided
        if not content_type:
            content_type, _ = mimetypes.guess_type(filename)
            if not content_type:
                content_type = "audio/mpeg"  # Default to MP3
        
        # Generate object key (path in bucket)
        object_key = f"speeches/{filename}"
        
        try:
            # Upload file
            self.client.upload_fileobj(
                file_data,
                self.bucket_name,
                object_key,
                ExtraArgs={"ContentType": content_type},
            )
            
            # Return public URL
            return self.get_public_url(object_key)
            
        except ClientError as e:
            raise StorageError(f"Failed to upload file: {str(e)}")
    
    def upload_from_bytes(
        self, data: bytes, filename: str, content_type: Optional[str] = None
    ) -> str:
        """
        Upload audio from bytes.
        
        Args:
            data: Audio file bytes
            filename: Desired filename
            content_type: MIME type
            
        Returns:
            Public URL of uploaded file
        """
        file_obj = io.BytesIO(data)
        return self.upload_audio(file_obj, filename, content_type)
    
    def get_public_url(self, object_key: str) -> str:
        """
        Get public URL for an object.
        
        Args:
            object_key: Object key in bucket
            
        Returns:
            Public URL
        """
        # URL encode the object key
        encoded_key = quote(object_key, safe="/")
        return f"{settings.s3_endpoint_url}/{self.bucket_name}/{encoded_key}"
    
    def get_signed_url(self, object_key: str, expires_in: int = 3600) -> str:
        """
        Generate presigned URL for temporary access.
        
        Args:
            object_key: Object key in bucket
            expires_in: Expiration time in seconds (default 1 hour)
            
        Returns:
            Presigned URL
            
        Raises:
            StorageError: If URL generation fails
        """
        try:
            url = self.client.generate_presigned_url(
                "get_object",
                Params={"Bucket": self.bucket_name, "Key": object_key},
                ExpiresIn=expires_in,
            )
            return url
        except ClientError as e:
            raise StorageError(f"Failed to generate signed URL: {str(e)}")
    
    def delete_file(self, object_key: str) -> None:
        """
        Delete an audio file from storage.
        
        Args:
            object_key: Object key to delete
            
        Raises:
            StorageError: If deletion fails
        """
        try:
            self.client.delete_object(Bucket=self.bucket_name, Key=object_key)
        except ClientError as e:
            raise StorageError(f"Failed to delete file: {str(e)}")
    
    def file_exists(self, object_key: str) -> bool:
        """
        Check if file exists in storage.
        
        Args:
            object_key: Object key to check
            
        Returns:
            True if file exists, False otherwise
        """
        try:
            self.client.head_object(Bucket=self.bucket_name, Key=object_key)
            return True
        except ClientError:
            return False
    
    def list_files(self, prefix: str = "") -> list[str]:
        """
        List files in bucket with optional prefix filter.
        
        Args:
            prefix: Prefix to filter by (e.g., "speeches/")
            
        Returns:
            List of object keys
            
        Raises:
            StorageError: If listing fails
        """
        try:
            response = self.client.list_objects_v2(
                Bucket=self.bucket_name, Prefix=prefix
            )
            
            if "Contents" not in response:
                return []
            
            return [obj["Key"] for obj in response["Contents"]]
            
        except ClientError as e:
            raise StorageError(f"Failed to list files: {str(e)}")
