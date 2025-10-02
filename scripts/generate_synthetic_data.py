from __future__ import annotations

import csv
from pathlib import Path

import boto3
from rich.console import Console

from services.common.config import get_settings
from services.common.data import SyntheticEventGenerator
from services.common.schemas import Event

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
    settings = get_settings()
    generator = SyntheticEventGenerator()
    out_path = Path("data/sample/events.csv")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=Event.model_fields.keys())
        writer.writeheader()
        for event in generator.stream(batch_size=500):
            writer.writerow(event.model_dump(mode="json"))
    console.print(f"[bold]Wrote synthetic dataset to[/bold] {out_path}")
    try:
        upload_to_minio(out_path)
    except Exception as exc:
        console.print(f"[yellow]Skipping MinIO upload: {exc}[/yellow]")


if __name__ == "__main__":
    main()
