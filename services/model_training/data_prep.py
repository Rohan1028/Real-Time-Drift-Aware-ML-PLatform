from __future__ import annotations

from pathlib import Path

import pandas as pd
from sklearn.model_selection import train_test_split


def load_training_frame(
    path: str | Path = "data/sample/events.csv",
) -> tuple[pd.DataFrame, pd.Series]:
    df = pd.read_csv(path, parse_dates=["event_ts"])
    df = df.dropna(subset=["label"])
    features = df[["transaction_amount", "country", "device", "event_ts"]].copy()
    target = df["label"].astype(int)
    return features, target


def split_data(features: pd.DataFrame, target: pd.Series, test_size: float = 0.2, seed: int = 42):
    return train_test_split(
        features, target, test_size=test_size, random_state=seed, stratify=target
    )
