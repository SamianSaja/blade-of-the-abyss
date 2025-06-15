from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
import numpy as np
from collections import deque

app = FastAPI()

# Load trained adaptive model
model = PPO.load("ppo_wraith_adaptive_v8")  # Pastikan path dan filename benar

# Track player style
player_style_history = deque(maxlen=50)  # Track last 50 interactions
MELEE_THRESHOLD = 8.0  # Distance threshold for melee attacks

# Track action history and combos
action_history = deque(maxlen=5)  # Track last 5 actions
combo_success = {
    "fighter": {
        "summon": {"tornado": 0, "full_tornado": 0},
        "tornado": {"full_tornado": 0, "retreat": 0},
        "full_tornado": {"retreat": 0, "chase": 0}
    },
    "mage": {
        "summon": {"tornado": 0, "chase": 0},
        "tornado": {"summon": 0, "retreat": 0},
        "retreat": {"summon": 0, "tornado": 0}
    },
    "balanced": {
        "summon": {"tornado": 0, "chase": 0},
        "tornado": {"full_tornado": 0, "retreat": 0},
        "full_tornado": {"retreat": 0, "chase": 0},
        "retreat": {"summon": 0, "tornado": 0},
        "chase": {"summon": 0, "tornado": 0}
    }
}

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

# Action list sesuai Env: 0=Summon, 1=Tornado, 2=Full Tornado, 3=Retreat, 4=Chase
actions = ["summon", "tornado", "full_tornado", "retreat", "chase"]

def analyze_player_style(distance: float, player_dps: float) -> str:
    """Analyze if player is using melee or ranged style"""
    is_melee = distance < MELEE_THRESHOLD
    player_style_history.append(is_melee)
    
    # Calculate percentage of melee attacks
    melee_percentage = sum(player_style_history) / len(player_style_history)
    
    if melee_percentage > 0.7:  # If more than 70% are melee attacks
        return "fighter"
    elif melee_percentage < 0.3:  # If less than 30% are melee attacks
        return "mage"
    else:
        return "balanced"

def get_best_combo(player_style: str, last_action: str) -> str:
    """Get the best next action based on combo success history"""
    if not last_action:
        return None
        
    # Handle balanced style with more flexible combos
    if player_style == "balanced":
        if last_action not in combo_success["balanced"]:
            return None
        combos = combo_success["balanced"][last_action]
    else:
        if last_action not in combo_success[player_style]:
            return None
        combos = combo_success[player_style][last_action]
    
    if not combos:
        return None
        
    # Get the action with highest success rate
    best_action = max(combos.items(), key=lambda x: x[1])[0]
    return best_action

def update_combo_success(player_style: str, action1: str, action2: str, damage_dealt: float):
    """Update combo success rate based on damage dealt"""
    # Handle balanced style
    if player_style == "balanced":
        if action1 in combo_success["balanced"] and action2 in combo_success["balanced"][action1]:
            if damage_dealt > 0:
                combo_success["balanced"][action1][action2] += 1
            else:
                combo_success["balanced"][action1][action2] = max(0, combo_success["balanced"][action1][action2] - 1)
    else:
        if action1 in combo_success[player_style] and action2 in combo_success[player_style][action1]:
            if damage_dealt > 0:
                combo_success[player_style][action1][action2] += 1
            else:
                combo_success[player_style][action1][action2] = max(0, combo_success[player_style][action1][action2] - 1)

@app.post("/predict")
async def predict(state: State):
    # Analyze player style
    player_style = analyze_player_style(state.distance, state.player_dps)
    
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
    predicted_action = actions[int(action)]
    
    # Check for combo opportunities
    last_action = action_history[-1] if action_history else None
    combo_action = get_best_combo(player_style, last_action)
    
    # Force more appropriate actions based on distance and player style
    if state.distance < 3.0:  # Danger zone
        if player_style == "fighter":
            if combo_action == "full_tornado" and state.can_full_tornado:
                predicted_action = "full_tornado"
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
            elif state.can_full_tornado:
                predicted_action = "full_tornado"
            elif state.can_tornado:
                predicted_action = "tornado"
            else:
                predicted_action = "retreat"
        else:
            if combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
            elif state.can_tornado:
                predicted_action = "tornado"
            else:
                predicted_action = "retreat"
    elif state.distance < 5.0:  # Combat zone
        if player_style == "fighter":
            if combo_action == "full_tornado" and state.can_full_tornado:
                predicted_action = "full_tornado"
            elif combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
            elif state.can_full_tornado:
                predicted_action = "full_tornado"
            elif state.can_summon:
                predicted_action = "summon"
            elif state.can_tornado:
                predicted_action = "tornado"
        elif player_style == "mage":
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
            elif state.can_summon:
                predicted_action = "summon"
            elif state.can_tornado:
                predicted_action = "tornado"
    elif state.distance < 7.0:  # Engagement zone
        if player_style == "fighter":
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
            elif state.can_summon:
                predicted_action = "summon"
            elif state.can_tornado:
                predicted_action = "tornado"
            else:
                predicted_action = "chase"
        elif player_style == "mage":
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
            elif state.can_summon:
                predicted_action = "summon"
            else:
                predicted_action = "chase"
    else:  # Long range
        if combo_action == "summon" and state.can_summon:
            predicted_action = "summon"
        elif state.can_summon:
            predicted_action = "summon"
        else:
            predicted_action = "chase"
    
    # Update action history
    action_history.append(predicted_action)
    
    # Log prediction details
    print(f"Player Style: {player_style}")
    print(f"Distance: {state.distance:.2f}")
    print(f"Original Action: {actions[int(action)]}")
    print(f"Combo Action: {combo_action}")
    print(f"Final Action: {predicted_action}")
    print(f"Action History: {list(action_history)}")
    
    return {
        "action": predicted_action,
        "player_style": player_style,
        "melee_percentage": sum(player_style_history) / len(player_style_history)
    }

@app.post("/test_combo")
async def test_combo():
    """Test endpoint to compare DRL vs fallback logic for combo attacks"""
    test_scenarios = [
        {
            "name": "Fighter Close Range",
            "state": State(
                enemy_hp=100,
                enemy_mp=100,
                player_hp=100,
                player_mp=100,
                distance=3.0,  # Close range
                player_dps=20,  # High DPS indicates fighter
                damage_taken=0,
                can_summon=True,
                can_tornado=True,
                can_full_tornado=True,
                tornado_cd=0,
                summon_cd=0,
                summon_count=0
            ),
            "expected_style": "fighter",
            "expected_combos": ["summon->tornado", "tornado->full_tornado"]
        },
        {
            "name": "Mage Long Range",
            "state": State(
                enemy_hp=100,
                enemy_mp=100,
                player_hp=100,
                player_mp=100,
                distance=15.0,  # Long range
                player_dps=5,  # Low DPS indicates mage
                damage_taken=0,
                can_summon=True,
                can_tornado=True,
                can_full_tornado=True,
                tornado_cd=0,
                summon_cd=0,
                summon_count=0
            ),
            "expected_style": "mage",
            "expected_combos": ["summon->tornado", "retreat->summon"]
        },
        {
            "name": "Balanced Mid Range",
            "state": State(
                enemy_hp=100,
                enemy_mp=100,
                player_hp=100,
                player_mp=100,
                distance=8.0,  # Mid range
                player_dps=10,  # Medium DPS indicates balanced
                damage_taken=0,
                can_summon=True,
                can_tornado=True,
                can_full_tornado=True,
                tornado_cd=0,
                summon_cd=0,
                summon_count=0
            ),
            "expected_style": "balanced",
            "expected_combos": ["summon->tornado", "tornado->full_tornado"]
        }
    ]
    
    results = []
    for scenario in test_scenarios:
        # Get DRL prediction
        drl_result = await predict(scenario["state"])
        
        # Simulate fallback logic
        fallback_action = simulate_fallback(scenario["state"])
        
        # Track combo success
        combo_success_rate = calculate_combo_success(
            scenario["state"],
            drl_result["action"],
            scenario["expected_combos"]
        )
        
        results.append({
            "scenario": scenario["name"],
            "player_style": drl_result["player_style"],
            "expected_style": scenario["expected_style"],
            "drl_action": drl_result["action"],
            "fallback_action": fallback_action,
            "combo_success_rate": combo_success_rate,
            "melee_percentage": drl_result["melee_percentage"]
        })
    
    return {
        "test_results": results,
        "combo_success_stats": {
            "fighter": combo_success["fighter"],
            "mage": combo_success["mage"],
            "balanced": combo_success["balanced"]
        }
    }

def simulate_fallback(state: State) -> str:
    """Simulate the fallback logic from EnemyWraith.gd"""
    if state.distance < 3.0:  # Danger zone
        if state.can_full_tornado:
            return "full_tornado"
        elif state.can_tornado:
            return "tornado"
        else:
            return "retreat"
    elif state.distance < 5.0:  # Combat zone
        if state.can_full_tornado:
            return "full_tornado"
        elif state.can_summon:
            return "summon"
        elif state.can_tornado:
            return "tornado"
        else:
            return "chase"
    elif state.distance < 7.0:  # Engagement zone
        if state.can_summon:
            return "summon"
        elif state.can_tornado:
            return "tornado"
        else:
            return "chase"
    else:  # Long range
        if state.can_summon:
            return "summon"
        else:
            return "chase"

def calculate_combo_success(state: State, action: str, expected_combos: list) -> float:
    """Calculate how well the action fits into expected combos"""
    if not action_history:
        return 0.0
        
    last_action = action_history[-1]
    current_combo = f"{last_action}->{action}"
    
    if current_combo in expected_combos:
        return 1.0
    return 0.0

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("drl_server:app", host="0.0.0.0", port=8000, reload=True)
