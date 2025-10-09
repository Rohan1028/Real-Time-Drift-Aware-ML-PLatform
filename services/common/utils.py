from __future__ import annotations

import time
from contextlib import contextmanager
from typing import Generator, Iterable, Iterator, Sequence, TypeVar

T = TypeVar("T")


def chunks(sequence: Sequence[T], size: int) -> Iterator[Sequence[T]]:
    if size <= 0:
        raise ValueError("size must be > 0")
    for idx in range(0, len(sequence), size):
        yield sequence[idx : idx + size]


@contextmanager
def observe_latency(metric, **labels) -> Generator[None, None, None]:
    start = time.perf_counter()
    try:
        yield
    finally:
        metric.labels(**labels).observe(time.perf_counter() - start)


def window(iterable: Iterable[T], n: int) -> Iterator[list[T]]:
    bucket: list[T] = []
    for item in iterable:
        bucket.append(item)
        if len(bucket) == n:
            yield bucket
            bucket = []
    if bucket:
        yield bucket
