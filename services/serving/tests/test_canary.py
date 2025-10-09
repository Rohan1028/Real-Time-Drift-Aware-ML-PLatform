from services.serving.app.canary import CanaryStrategy


def test_canary_probability_bounds():
    strategy = CanaryStrategy(split=0.3)
    for _ in range(10):
        decision = strategy.choose()
        assert decision.variant in {"baseline", "canary"}
        assert 0 <= decision.probability <= 1
