from __future__ import annotations

from pathlib import Path

import boto3
import pandas as pd
from rich.console import Console

from services.common.config import get_settings
from services.common.data import SyntheticEventGenerator

console = Console()


def upload_to_minio(path: Path) -> None:
    settings = get_settings()
    client = boto3.client(
        "s3",
        endpoint_url=settings.minio_endpoint,
        aws_access_key_id=settings.minio_access_key,
        aws_secret_access_key=settings.minio_secret_key,
    )
    client.upload_file(str(path), settings.minio_bucket, f"offline/{path.name}")
    console.print(
        f"Uploaded {path} to s3://{settings.minio_bucket}/offline/{path.name}", style="green"
    )


def main() -> None:
    generator = SyntheticEventGenerator()
    output_dir = Path("data/sample")
    output_dir.mkdir(parents=True, exist_ok=True)

    events = [event.model_dump() for event in generator.stream(batch_size=500)]
    df = pd.DataFrame(events)
    df["created_at"] = pd.Timestamp.now(tz="UTC")

    csv_path = output_dir / "events.csv"
    parquet_path = output_dir / "events.parquet"

    df.to_csv(csv_path, index=False)
    df.to_parquet(parquet_path, index=False)

    console.print(f"[bold]Wrote synthetic dataset to[/bold] {csv_path} and {parquet_path}")
    try:
        upload_to_minio(csv_path)
    except Exception as exc:
        console.print(f"[yellow]Skipping MinIO upload: {exc}[/yellow]")


if __name__ == "__main__":
    main()
