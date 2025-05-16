from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
import numpy as np

app = FastAPI()
model = PPO.load("ppo_wraith_v3")  # Ensure this matches your trained model filename

class State(BaseModel):
    enemy_hp: float
    enemy_mp: float
    player_hp: float
    player_mp: float
    distance: float
    player_dps: float
    damage_taken: float
    can_summon: bool
    can_tornado: bool
    summon_count: int
    tornado_cd: float
    summon_cd: float

actions = ["summon", "tornado", "attack", "retreat", "chase"]

@app.post("/predict")
async def predict(state: State):
    obs = np.array([
        state.enemy_hp,
        state.enemy_mp,
        state.player_hp,
        state.player_mp,
        state.distance,
        state.player_dps,
        state.damage_taken,
        float(state.can_summon),
        float(state.can_tornado),
        state.summon_count,
        state.tornado_cd,
        state.summon_cd
    ], dtype=np.float32)
    action, _ = model.predict(obs, deterministic=True)
    return {"action": actions[int(action)]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("drl_server:app", host="0.0.0.0", port=8000, reload=True)