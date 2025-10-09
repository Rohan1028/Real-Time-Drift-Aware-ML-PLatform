from services.common.data import SyntheticEventGenerator


def test_generator_produces_labels():
    gen = SyntheticEventGenerator(seed=1)
    event = gen.sample(user_id="user-1")
    assert event.user_id == "user-1"
    assert event.transaction_amount >= 0
