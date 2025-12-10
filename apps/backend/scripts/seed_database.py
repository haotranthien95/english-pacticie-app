#!/usr/bin/env python3
"""Database seeding script for development and testing."""
import sys
import os
from pathlib import Path

# Add app directory to Python path
backend_dir = Path(__file__).parent.parent
sys.path.insert(0, str(backend_dir))

import asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from passlib.context import CryptContext

from app.config import settings
from app.database import Base
from app.models import (
    User,
    AuthProvider,
    Tag,
    Speech,
    Level,
    SpeechType,
    GameSession,
    GameMode,
    GameResult,
    UserResponse,
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def seed_tags(session: AsyncSession) -> dict[str, list]:
    """Create tag data. Returns dict of category to list of tags."""
    # Check if tags already exist
    result = await session.execute(select(Tag))
    existing_tags = result.scalars().all()
    if existing_tags:
        print(f"✓ Tags already exist ({len(existing_tags)} tags), skipping...")
        return {"tense": [], "topic": []}

    tense_tags_data = [
        "present_simple",
        "present_continuous",
        "present_perfect",
        "past_simple",
        "past_continuous",
        "past_perfect",
        "future_simple",
        "future_continuous",
        "conditional",
        "modal_verbs",
    ]

    topic_tags_data = [
        "daily_life",
        "work_business",
        "travel",
        "food_dining",
        "health_fitness",
        "education",
        "technology",
        "entertainment",
        "relationships",
        "shopping",
        "weather",
        "hobbies",
    ]

    tense_tags = []
    topic_tags = []

    for name in tense_tags_data:
        tag = Tag(name=name, category="tense")
        session.add(tag)
        tense_tags.append(tag)

    for name in topic_tags_data:
        tag = Tag(name=name, category="topic")
        session.add(tag)
        topic_tags.append(tag)

    await session.flush()  # Flush to assign IDs
    print(f"✓ Created {len(tense_tags)} tense tags and {len(topic_tags)} topic tags")

    return {"tense": tense_tags, "topic": topic_tags}


async def seed_speeches(session: AsyncSession, tags_dict: dict) -> list:
    """Create speech practice data."""
    # Check if speeches already exist
    result = await session.execute(select(Speech))
    existing_speeches = result.scalars().all()
    if existing_speeches:
        print(f"✓ Speeches already exist ({len(existing_speeches)} speeches), skipping...")
        return []

    speeches_data = [
        # A1 Level (Beginner) - Daily Life
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a1-daily-life-001.mp3",
            "text": "Hello, my name is John. I live in London.",
            "level": Level.A1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_simple", "daily_life"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a1-daily-life-002.mp3",
            "text": "I am eating breakfast now.",
            "level": Level.A1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_continuous", "food_dining"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a1-daily-life-003.mp3",
            "text": "What is your name?",
            "level": Level.A1,
            "type": SpeechType.QUESTION,
            "tag_names": ["present_simple", "daily_life"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a1-food-001.mp3",
            "text": "I like pizza and pasta.",
            "level": Level.A1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_simple", "food_dining"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a1-weather-001.mp3",
            "text": "It is sunny today.",
            "level": Level.A1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_simple", "weather"],
        },
        # A2 Level - Shopping & Hobbies
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a2-shopping-001.mp3",
            "text": "I went to the store yesterday and bought some clothes.",
            "level": Level.A2,
            "type": SpeechType.ANSWER,
            "tag_names": ["past_simple", "shopping"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a2-hobbies-001.mp3",
            "text": "I am learning to play the guitar.",
            "level": Level.A2,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_continuous", "hobbies"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a2-travel-001.mp3",
            "text": "Where did you go on vacation last summer?",
            "level": Level.A2,
            "type": SpeechType.QUESTION,
            "tag_names": ["past_simple", "travel"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a2-work-001.mp3",
            "text": "I have worked here for two years.",
            "level": Level.A2,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_perfect", "work_business"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/a2-health-001.mp3",
            "text": "I should exercise more often.",
            "level": Level.A2,
            "type": SpeechType.ANSWER,
            "tag_names": ["modal_verbs", "health_fitness"],
        },
        # B1 Level (Intermediate) - Work & Technology
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b1-work-001.mp3",
            "text": "I have been working on this project for three months now.",
            "level": Level.B1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_perfect", "work_business"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b1-tech-001.mp3",
            "text": "Technology has changed the way we communicate with each other.",
            "level": Level.B1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_perfect", "technology"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b1-education-001.mp3",
            "text": "If I had studied harder, I would have passed the exam.",
            "level": Level.B1,
            "type": SpeechType.ANSWER,
            "tag_names": ["conditional", "education"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b1-travel-001.mp3",
            "text": "I was traveling through Europe when I met my best friend.",
            "level": Level.B1,
            "type": SpeechType.ANSWER,
            "tag_names": ["past_continuous", "travel", "relationships"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b1-entertainment-001.mp3",
            "text": "Have you seen the new movie that came out last week?",
            "level": Level.B1,
            "type": SpeechType.QUESTION,
            "tag_names": ["present_perfect", "entertainment"],
        },
        # B2 Level - Business & Complex Topics
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b2-business-001.mp3",
            "text": "By the time the meeting started, I had already prepared all the documents.",
            "level": Level.B2,
            "type": SpeechType.ANSWER,
            "tag_names": ["past_perfect", "work_business"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b2-tech-001.mp3",
            "text": "Artificial intelligence will be transforming industries within the next decade.",
            "level": Level.B2,
            "type": SpeechType.ANSWER,
            "tag_names": ["future_continuous", "technology"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b2-health-001.mp3",
            "text": "If people had access to better healthcare, life expectancy would increase significantly.",
            "level": Level.B2,
            "type": SpeechType.ANSWER,
            "tag_names": ["conditional", "health_fitness"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b2-education-001.mp3",
            "text": "The education system must adapt to prepare students for the challenges of tomorrow.",
            "level": Level.B2,
            "type": SpeechType.ANSWER,
            "tag_names": ["modal_verbs", "education"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/b2-work-002.mp3",
            "text": "What strategies would you recommend for improving team productivity?",
            "level": Level.B2,
            "type": SpeechType.QUESTION,
            "tag_names": ["conditional", "work_business"],
        },
        # C1 Level (Advanced) - Complex Topics
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/c1-business-001.mp3",
            "text": "Having thoroughly analyzed the market trends, we can conclude that consumer behavior has shifted dramatically.",
            "level": Level.C1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_perfect", "work_business"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/c1-tech-001.mp3",
            "text": "The implementation of blockchain technology could potentially revolutionize financial transactions worldwide.",
            "level": Level.C1,
            "type": SpeechType.ANSWER,
            "tag_names": ["modal_verbs", "technology"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/c1-education-001.mp3",
            "text": "Had the government invested more in education earlier, we would have seen significantly better outcomes by now.",
            "level": Level.C1,
            "type": SpeechType.ANSWER,
            "tag_names": ["conditional", "education"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/c1-health-001.mp3",
            "text": "The correlation between mental health and physical well-being has been extensively documented in recent research.",
            "level": Level.C1,
            "type": SpeechType.ANSWER,
            "tag_names": ["present_perfect", "health_fitness"],
        },
        {
            "audio_url": "https://minio.local:9000/english-practice-audio/c1-relationships-001.mp3",
            "text": "How do you think cultural differences influence the way people approach interpersonal relationships?",
            "level": Level.C1,
            "type": SpeechType.QUESTION,
            "tag_names": ["present_simple", "relationships"],
        },
    ]

    # Create tag lookup
    all_tags = tags_dict["tense"] + tags_dict["topic"]
    tag_lookup = {tag.name: tag for tag in all_tags}

    speeches = []
    for data in speeches_data:
        speech = Speech(
            audio_url=data["audio_url"],
            text=data["text"],
            level=data["level"],
            type=data["type"],
        )
        # Add tags
        for tag_name in data["tag_names"]:
            if tag_name in tag_lookup:
                speech.tags.append(tag_lookup[tag_name])

        session.add(speech)
        speeches.append(speech)

    await session.flush()
    print(f"✓ Created {len(speeches)} speeches across all levels")
    return speeches


async def seed_users(session: AsyncSession) -> list:
    """Create test users."""
    # Check if users already exist
    result = await session.execute(select(User))
    existing_users = result.scalars().all()
    if existing_users:
        print(f"✓ Users already exist ({len(existing_users)} users), skipping...")
        return []

    users_data = [
        {
            "email": "john.doe@example.com",
            "name": "John Doe",
            "password": "Password123!",
            "auth_provider": AuthProvider.EMAIL,
        },
        {
            "email": "jane.smith@example.com",
            "name": "Jane Smith",
            "password": "SecurePass456!",
            "auth_provider": AuthProvider.EMAIL,
        },
        {
            "email": "bob.wilson@gmail.com",
            "name": "Bob Wilson",
            "auth_provider": AuthProvider.GOOGLE,
            "auth_provider_id": "google_123456789",
        },
        {
            "email": "alice.johnson@icloud.com",
            "name": "Alice Johnson",
            "auth_provider": AuthProvider.APPLE,
            "auth_provider_id": "apple_987654321",
        },
        {
            "email": "charlie.brown@fb.com",
            "name": "Charlie Brown",
            "auth_provider": AuthProvider.FACEBOOK,
            "auth_provider_id": "facebook_111222333",
        },
    ]

    users = []
    for data in users_data:
        user = User(
            email=data["email"],
            name=data["name"],
            auth_provider=data["auth_provider"],
            auth_provider_id=data.get("auth_provider_id"),
        )

        # Hash password only for email provider
        if data["auth_provider"] == AuthProvider.EMAIL and "password" in data:
            user.password_hash = pwd_context.hash(data["password"])

        session.add(user)
        users.append(user)

    await session.flush()
    print(f"✓ Created {len(users)} test users")
    return users


async def seed_game_sessions(
    session: AsyncSession, users: list, speeches: list
) -> None:
    """Create sample game sessions and results."""
    # Check if game sessions already exist
    result = await session.execute(select(GameSession))
    existing_sessions = result.scalars().all()
    if existing_sessions:
        print(
            f"✓ Game sessions already exist ({len(existing_sessions)} sessions), skipping..."
        )
        return

    if not users or not speeches:
        print("! Skipping game sessions (no users or speeches available)")
        return

    # Create 2 sample sessions for the first user
    user = users[0]

    # Session 1: Listen only mode, A1 level
    a1_speeches = [s for s in speeches if s.level == Level.A1][:3]
    session1 = GameSession(
        user_id=user.id,
        mode=GameMode.LISTEN_ONLY,
        level=Level.A1,
        selected_tags=[],  # Empty for listen-only
        total_speeches=len(a1_speeches),
        correct_count=2,
        incorrect_count=1,
        skipped_count=0,
    )
    session.add(session1)
    await session.flush()

    # Add results for session 1
    for idx, speech in enumerate(a1_speeches):
        result = GameResult(
            session_id=session1.id,
            speech_id=speech.id,
            sequence_number=idx + 1,
            user_response=UserResponse.CORRECT if idx < 2 else UserResponse.INCORRECT,
        )
        session.add(result)

    # Session 2: Listen and repeat mode, B1 level
    b1_speeches = [s for s in speeches if s.level == Level.B1][:4]
    session2 = GameSession(
        user_id=user.id,
        mode=GameMode.LISTEN_AND_REPEAT,
        level=Level.B1,
        selected_tags=[],
        total_speeches=len(b1_speeches),
        correct_count=3,
        incorrect_count=0,
        skipped_count=1,
        avg_pronunciation_score=82.5,
        avg_accuracy_score=78.3,
        avg_fluency_score=85.7,
    )
    session.add(session2)
    await session.flush()

    # Add results for session 2 with pronunciation scores
    for idx, speech in enumerate(b1_speeches):
        if idx == 3:
            # Last one skipped
            result = GameResult(
                session_id=session2.id,
                speech_id=speech.id,
                sequence_number=idx + 1,
                user_response=UserResponse.SKIPPED,
            )
        else:
            result = GameResult(
                session_id=session2.id,
                speech_id=speech.id,
                sequence_number=idx + 1,
                user_response=UserResponse.CORRECT,
                recognized_text=speech.text,  # Perfect transcription
                pronunciation_score=80.0 + (idx * 5),
                accuracy_score=75.0 + (idx * 5),
                fluency_score=85.0 + (idx * 2),
                completeness_score=95.0,
                word_scores=[
                    {"word": word, "score": 85.0 + idx, "error_type": None}
                    for word in speech.text.split()[:5]  # First 5 words
                ],
            )
        session.add(result)

    print(f"✓ Created 2 sample game sessions with results")


async def main():
    """Main seeding function."""
    print("\n🌱 Starting database seeding...\n")

    # Create async engine
    engine = create_async_engine(settings.database_url, echo=False)

    # Create tables if they don't exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create session
    async with AsyncSession(engine) as session:
        try:
            # Seed in order (respecting foreign keys)
            tags_dict = await seed_tags(session)
            speeches = await seed_speeches(session, tags_dict)
            users = await seed_users(session)
            await seed_game_sessions(session, users, speeches)

            # Commit all changes
            await session.commit()
            print("\n✅ Database seeding completed successfully!\n")

        except Exception as e:
            await session.rollback()
            print(f"\n❌ Error during seeding: {e}\n")
            raise

        finally:
            await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
