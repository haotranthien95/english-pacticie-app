"""
SQLAdmin ModelView configurations for admin panel.

Defines admin interface views for Speech, Tag, User, and GameSession models.
Configures columns, filters, search, and CRUD permissions per model.
"""
from sqladmin import ModelView

from app.models import GameSession, Speech, Tag, User


class SpeechAdmin(ModelView, model=Speech):
    """
    Admin view for Speech model.
    
    Features:
    - Full CRUD operations (create, edit, delete)
    - Search by text content
    - Filter by level, type
    - Sort by level, created_at
    - Display tags as related items
    """
    
    # Display configuration
    name = "Speech"
    name_plural = "Speeches"
    icon = "fa-solid fa-microphone"
    
    # Column configuration
    column_list = [
        Speech.id,
        Speech.text,
        Speech.level,
        Speech.type,
        Speech.audio_url,
        Speech.created_at,
        Speech.updated_at,
    ]
    
    column_details_list = [
        Speech.id,
        Speech.text,
        Speech.level,
        Speech.type,
        Speech.audio_url,
        Speech.tags,
        Speech.created_at,
        Speech.updated_at,
    ]
    
    # Search configuration
    column_searchable_list = [Speech.text]
    
    # Filter configuration
    column_filters = [Speech.level, Speech.type]
    
    # Sorting configuration
    column_sortable_list = [Speech.level, Speech.type, Speech.created_at, Speech.updated_at]
    
    # Default sorting
    column_default_sort = [(Speech.created_at, True)]  # DESC
    
    # CRUD permissions
    can_create = True
    can_edit = True
    can_delete = True
    can_view_details = True
    
    # Pagination
    page_size = 50
    page_size_options = [25, 50, 100, 200]
    
    # Form configuration
    form_columns = [
        Speech.text,
        Speech.audio_url,
        Speech.level,
        Speech.type,
        Speech.tags,
    ]
    
    # Column labels
    column_labels = {
        Speech.id: "ID",
        Speech.text: "Text Content",
        Speech.level: "CEFR Level",
        Speech.type: "Type",
        Speech.audio_url: "Audio URL",
        Speech.tags: "Tags",
        Speech.created_at: "Created",
        Speech.updated_at: "Updated",
    }
    
    # Column formatters (optional)
    column_formatters = {
        Speech.text: lambda m, a: m.text[:100] + "..." if len(m.text) > 100 else m.text,
        Speech.audio_url: lambda m, a: m.audio_url[:50] + "..." if len(m.audio_url) > 50 else m.audio_url,
    }


class TagAdmin(ModelView, model=Tag):
    """
    Admin view for Tag model.
    
    Features:
    - Full CRUD operations
    - Search by name
    - Filter by category
    - Display associated speeches count
    - Unique name validation
    """
    
    # Display configuration
    name = "Tag"
    name_plural = "Tags"
    icon = "fa-solid fa-tag"
    
    # Column configuration
    column_list = [
        Tag.id,
        Tag.name,
        Tag.category,
        Tag.created_at,
    ]
    
    column_details_list = [
        Tag.id,
        Tag.name,
        Tag.category,
        Tag.created_at,
    ]
    
    # Search configuration
    column_searchable_list = [Tag.name]
    
    # Filter configuration
    column_filters = [Tag.category]
    
    # Sorting configuration
    column_sortable_list = [Tag.name, Tag.category, Tag.created_at]
    
    # Default sorting
    column_default_sort = [(Tag.name, False)]  # ASC
    
    # CRUD permissions
    can_create = True
    can_edit = True
    can_delete = True
    can_view_details = True
    
    # Pagination
    page_size = 100
    page_size_options = [50, 100, 200]
    
    # Form configuration
    form_columns = [
        Tag.name,
        Tag.category,
    ]
    
    # Column labels
    column_labels = {
        Tag.id: "ID",
        Tag.name: "Tag Name",
        Tag.category: "Category",
        Tag.created_at: "Created",
    }


class UserAdmin(ModelView, model=User):
    """
    Admin view for User model.
    
    Features:
    - View and edit users (no creation via admin)
    - Search by email, name
    - Filter by auth_provider
    - Delete users (cascade deletes sessions/results)
    - Cannot create users (only via API registration)
    """
    
    # Display configuration
    name = "User"
    name_plural = "Users"
    icon = "fa-solid fa-user"
    
    # Column configuration
    column_list = [
        User.id,
        User.email,
        User.name,
        User.auth_provider,
        User.created_at,
        User.updated_at,
    ]
    
    column_details_list = [
        User.id,
        User.email,
        User.name,
        User.avatar_url,
        User.auth_provider,
        User.auth_provider_id,
        User.created_at,
        User.updated_at,
    ]
    
    # Search configuration
    column_searchable_list = [User.email, User.name]
    
    # Filter configuration
    column_filters = [User.auth_provider]
    
    # Sorting configuration
    column_sortable_list = [User.email, User.name, User.created_at, User.updated_at]
    
    # Default sorting
    column_default_sort = [(User.created_at, True)]  # DESC
    
    # CRUD permissions
    can_create = False  # Users created via API registration only
    can_edit = True     # Allow editing profile fields
    can_delete = True   # Allow account deletion
    can_view_details = True
    
    # Pagination
    page_size = 50
    page_size_options = [25, 50, 100]
    
    # Form configuration (for edit only)
    form_columns = [
        User.name,
        User.avatar_url,
    ]
    
    # Column labels
    column_labels = {
        User.id: "ID",
        User.email: "Email",
        User.name: "Name",
        User.avatar_url: "Avatar URL",
        User.auth_provider: "Auth Provider",
        User.auth_provider_id: "Provider ID",
        User.created_at: "Created",
        User.updated_at: "Updated",
    }
    
    # Exclude sensitive fields from display
    column_exclude_list = [User.password_hash]
    form_excluded_columns = [User.password_hash, User.email, User.auth_provider, User.auth_provider_id]


class GameSessionAdmin(ModelView, model=GameSession):
    """
    Admin view for GameSession model.
    
    Features:
    - View game sessions (no creation/editing via admin)
    - Search by user_id
    - Filter by mode, level
    - Sort by completed_at
    - Display session statistics
    - Delete sessions (cascade deletes results)
    """
    
    # Display configuration
    name = "Game Session"
    name_plural = "Game Sessions"
    icon = "fa-solid fa-gamepad"
    
    # Column configuration
    column_list = [
        GameSession.id,
        GameSession.user_id,
        GameSession.mode,
        GameSession.level,
        GameSession.total_speeches,
        GameSession.avg_accuracy,
        GameSession.avg_fluency,
        GameSession.completed_at,
    ]
    
    column_details_list = [
        GameSession.id,
        GameSession.user_id,
        GameSession.mode,
        GameSession.level,
        GameSession.total_speeches,
        GameSession.avg_accuracy,
        GameSession.avg_fluency,
        GameSession.avg_completeness,
        GameSession.avg_pronunciation,
        GameSession.started_at,
        GameSession.completed_at,
    ]
    
    # Filter configuration
    column_filters = [GameSession.mode, GameSession.level, GameSession.completed_at]
    
    # Sorting configuration
    column_sortable_list = [
        GameSession.mode,
        GameSession.level,
        GameSession.total_speeches,
        GameSession.avg_accuracy,
        GameSession.completed_at,
    ]
    
    # Default sorting
    column_default_sort = [(GameSession.completed_at, True)]  # DESC
    
    # CRUD permissions
    can_create = False  # Sessions created via API only
    can_edit = False    # Sessions are immutable
    can_delete = True   # Allow deletion for data cleanup
    can_view_details = True
    
    # Pagination
    page_size = 50
    page_size_options = [25, 50, 100]
    
    # Column labels
    column_labels = {
        GameSession.id: "Session ID",
        GameSession.user_id: "User ID",
        GameSession.mode: "Game Mode",
        GameSession.level: "Level",
        GameSession.total_speeches: "Total Speeches",
        GameSession.avg_accuracy: "Avg Accuracy",
        GameSession.avg_fluency: "Avg Fluency",
        GameSession.avg_completeness: "Avg Completeness",
        GameSession.avg_pronunciation: "Avg Pronunciation",
        GameSession.started_at: "Started",
        GameSession.completed_at: "Completed",
    }
    
    # Column formatters for percentages
    column_formatters = {
        GameSession.avg_accuracy: lambda m, a: f"{m.avg_accuracy:.1f}%" if m.avg_accuracy else "N/A",
        GameSession.avg_fluency: lambda m, a: f"{m.avg_fluency:.1f}%" if m.avg_fluency else "N/A",
        GameSession.avg_completeness: lambda m, a: f"{m.avg_completeness:.1f}%" if m.avg_completeness else "N/A",
        GameSession.avg_pronunciation: lambda m, a: f"{m.avg_pronunciation:.1f}%" if m.avg_pronunciation else "N/A",
    }
