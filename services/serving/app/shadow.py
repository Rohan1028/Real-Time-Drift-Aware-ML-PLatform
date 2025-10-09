import pandas as pd


class ShadowInvoker:
    def __init__(self, model) -> None:
        self.model = model

    async def submit(self, payload) -> None:
        frame = pd.DataFrame([payload])
        self.model.predict_proba(frame)
