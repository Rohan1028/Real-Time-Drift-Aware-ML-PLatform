from services.feature_service.feast_repo.feature_views import transaction_features


def test_transaction_feature_view_schema():
    fields = {field.name for field in transaction_features.schema}
    assert {"transaction_amount", "label"}.issubset(fields)
