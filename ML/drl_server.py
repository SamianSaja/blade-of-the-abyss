from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
import numpy as np

app = FastAPI()

# Load trained adaptive model
model = PPO.load("ppo_wraith_adaptive_v7")  # Pastikan path dan filename benar

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
    can_full_tornado: bool
    tornado_cd: float
    summon_cd: float
    summon_count: int = 0

# Action list sesuai Env: 0=Summon, 1=Tornado, 2=Full Tornado, 3=Attack, 4=Retreat, 5=Chase
actions = ["summon", "tornado", "full_tornado", "retreat", "chase"]

@app.post("/predict")
async def predict(state: State):
    # Convert incoming state to numpy observation
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
        float(state.can_full_tornado),
        state.tornado_cd,
        state.summon_cd,
        state.summon_count
    ], dtype=np.float32)

    # Predict action using the PPO model
    action, _states = model.predict(obs, deterministic=True)
    return {"action": actions[int(action)]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("drl_server:app", host="0.0.0.0", port=8000, reload=True)
