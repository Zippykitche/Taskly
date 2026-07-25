from __future__ import annotations
from sqlalchemy.orm import Session

from shared.models.db_models import Rating, User


class RatingsService:
    def create_rating(
        self,
        db: Session,
        job_id: int,
        rater_id: int,
        ratee_id: int,
        score: int,
        comment: str | None = None,
    ) -> Rating:
        if score < 1 or score > 5:
            raise ValueError("Rating score must be between 1 and 5")

        existing = (
            db.query(Rating)
            .filter(
                Rating.job_id == job_id,
                Rating.rater_id == rater_id,
                Rating.ratee_id == ratee_id,
            )
            .first()
        )
        if existing:
            raise ValueError("Rating already exists for this job and user")

        rating = Rating(
            job_id=job_id,
            rater_id=rater_id,
            ratee_id=ratee_id,
            score=score,
            comment=comment,
        )
        db.add(rating)
        db.commit()
        db.refresh(rating)

        self.recalculate_user_rating(db, ratee_id)
        return rating

    def recalculate_user_rating(self, db: Session, user_id: int) -> float:
        ratings = db.query(Rating).filter(Rating.ratee_id == user_id).all()
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("User not found")

        if not ratings:
            user.rating = 5.0
        else:
            user.rating = round(sum(rating.score for rating in ratings) / len(ratings), 2)

        db.commit()
        return user.rating

    def get_user_ratings(self, db: Session, user_id: int) -> list[Rating]:
        return (
            db.query(Rating)
            .filter(Rating.ratee_id == user_id)
            .order_by(Rating.created_at.desc())
            .all()
        )


ratings_service = RatingsService()
