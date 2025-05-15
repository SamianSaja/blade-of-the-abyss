from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
import numpy as np

app = FastAPI()
model = PPO.load("ppo_wraith")

class State(BaseModel):
    enemy_pos: list
    player_pos: list
    hp: float
    mp: float
    distance: float
    can_summon: bool
    can_tornado: bool

actions = ["summon", "tornado", "attack", "retreat", "chase"]

@app.post("/predict")
async def predict(state: State):
    obs = np.array([
        *state.enemy_pos,
        *state.player_pos,
        state.hp,
        state.mp,
        state.distance,
        float(state.can_summon),
        float(state.can_tornado)
    ], dtype=np.float32)
    action, _ = model.predict(obs, deterministic=True)
    return {"action": actions[int(action)]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("drl_server:app", host="0.0.0.0", port=8000, reload=True)