from services.model_training.data_prep import load_training_frame, split_data


def test_load_training_frame(tmp_path):
    path = tmp_path / "events.csv"
    path.write_text(
        "transaction_amount,country,device,event_ts,label\n1,US,ios,2024-01-01T00:00:00Z,1\n",
        encoding="utf-8",
    )
    features, target = load_training_frame(path)
    assert "transaction_amount" in features.columns
    assert target.iloc[0] == 1


def test_split_data():
    features, target = load_training_frame("data/sample/events.csv")
    X_train, X_test, _, _ = split_data(features, target, test_size=0.3)
    assert len(X_train) > len(X_test)
