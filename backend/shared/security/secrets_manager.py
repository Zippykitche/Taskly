from __future__ import annotations
import os
from typing import Any, Dict


class SecretsManager:
    """Lightweight secrets loader with safe defaults for local development."""

    REQUIRED_SECRETS = ["JWT_SECRET"]

    @staticmethod
    def get_secret(name: str, default: str | None = None) -> str:
        return os.getenv(name, default or "")

    @staticmethod
    def validate_required_secrets() -> None:
        missing = [name for name in SecretsManager.REQUIRED_SECRETS if not SecretsManager.get_secret(name)]
        if missing:
            raise ValueError(f"Missing required secrets: {', '.join(missing)}")

    @staticmethod
    def get_all() -> Dict[str, Any]:
        return {name: SecretsManager.get_secret(name) for name in SecretsManager.REQUIRED_SECRETS}
