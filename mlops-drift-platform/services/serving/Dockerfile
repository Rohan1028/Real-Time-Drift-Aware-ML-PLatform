FROM python:3.11-slim
WORKDIR /workspace
ENV PYTHONUNBUFFERED=1
COPY pyproject.toml README.md ./
COPY services ./services
COPY scripts ./scripts
RUN pip install --no-cache-dir poetry && \
    poetry config virtualenvs.create false && \
    poetry install --only main
CMD ["python", "services/serving/app/main.py"]
