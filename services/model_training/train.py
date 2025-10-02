from __future__ import annotations

import json
from pathlib import Path

import mlflow
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import average_precision_score, roc_auc_score
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

from services.common.config import get_settings
from services.common.logging import configure_logging, get_logger
from .data_prep import load_training_frame, split_data

logger = get_logger(__name__)


def build_pipeline() -> Pipeline:
    numeric_features = ["transaction_amount"]
    categorical_features = ["country", "device"]

    numeric_transformer = Pipeline(steps=[("scaler", StandardScaler())])
    categorical_transformer = Pipeline(steps=[("encoder", OneHotEncoder(handle_unknown="ignore"))])

    preprocessor = ColumnTransformer(
        transformers=[
            ("num", numeric_transformer, numeric_features),
            ("cat", categorical_transformer, categorical_features),
        ]
    )

    clf = LogisticRegression(max_iter=200, n_jobs=1)
    return Pipeline(steps=[("preprocess", preprocessor), ("model", clf)])


def train() -> None:
    configure_logging()
    settings = get_settings()
    mlflow.set_tracking_uri(settings.mlflow_tracking_uri)
    features, target = load_training_frame()
    X_train, X_test, y_train, y_test = split_data(features, target)
    pipeline = build_pipeline()
    with mlflow.start_run(run_name="training") as run:
        pipeline.fit(X_train, y_train)
        preds = pipeline.predict_proba(X_test)[:, 1]
        auc = roc_auc_score(y_test, preds)
        pr = average_precision_score(y_test, preds)
        mlflow.log_metric("roc_auc", float(auc))
        mlflow.log_metric("avg_precision", float(pr))
        mlflow.log_params({"n_train": len(X_train), "n_test": len(X_test)})
        signature = mlflow.models.infer_signature(X_test, preds)
        mlflow.sklearn.log_model(pipeline, artifact_path="model", signature=signature)
        Path("services/model_training/latest_metrics.json").write_text(
            json.dumps({"roc_auc": auc, "avg_precision": pr}),
            encoding="utf-8",
        )
        logger.info("Logged run %s", run.info.run_id)
    logger.info("Training complete - AUC=%.3f AP=%.3f", auc, pr)


if __name__ == "__main__":
    train()
