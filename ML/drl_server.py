from fastapi import FastAPI
from pydantic import BaseModel
from stable_baselines3 import PPO
import numpy as np
from collections import deque
import time
import logging
import json
from pathlib import Path
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('drl_server.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI()

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

# Load trained adaptive model
logger.info("Loading PPO model from ppo_wraith_adaptive_v8")
model = PPO.load("ppo_wraith_adaptive_v8")  # Pastikan path dan filename benar
logger.info("PPO model loaded successfully")

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

# Track rewards and episode state
reward_history = {
    "total_reward": 0.0,
    "episode_rewards": [],
    "current_episode_reward": 0.0,
    "episode_count": 0,
    "average_reward": 0.0,
    "max_reward": float('-inf'),
    "min_reward": float('inf'),
    "episode_stats": {
        "agent_deaths": 0,
        "player_deaths": 0,
        "episode_duration": 0,
        "damage_dealt": 0,
        "damage_taken": 0,
        "successful_combos": 0,
        "failed_combos": 0
    }
}

# Create rewards directory if it doesn't exist
rewards_dir = Path("rewards")
rewards_dir.mkdir(exist_ok=True)

def save_reward_history():
    """Save reward history to a JSON file"""
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    reward_file = rewards_dir / f"reward_history_{timestamp}.json"
    
    reward_data = {
        "total_reward": reward_history["total_reward"],
        "episode_rewards": reward_history["episode_rewards"],
        "episode_count": reward_history["episode_count"],
        "average_reward": reward_history["average_reward"],
        "max_reward": reward_history["max_reward"],
        "min_reward": reward_history["min_reward"],
        "episode_stats": reward_history["episode_stats"]
    }
    
    with open(reward_file, 'w') as f:
        json.dump(reward_data, f, indent=4)
    
    logger.info(f"Reward history saved to {reward_file}")

def update_reward_history(reward: float, state: State = None, is_episode_end: bool = False):
    """Update reward history with new reward and episode stats"""
    reward_history["current_episode_reward"] += reward
    reward_history["total_reward"] += reward
    
    if state:
        # Update episode stats
        reward_history["episode_stats"]["damage_dealt"] += state.damage_taken
        reward_history["episode_stats"]["damage_taken"] += (100 - state.player_hp)
        reward_history["episode_stats"]["episode_duration"] += 1
        
        # Check for successful combos
        if action_history and state.damage_taken > 0:
            reward_history["episode_stats"]["successful_combos"] += 1
        elif action_history:
            reward_history["episode_stats"]["failed_combos"] += 1
    
    if is_episode_end:
        episode_reward = reward_history["current_episode_reward"]
        reward_history["episode_rewards"].append(episode_reward)
        reward_history["episode_count"] += 1
        reward_history["max_reward"] = max(reward_history["max_reward"], episode_reward)
        reward_history["min_reward"] = min(reward_history["min_reward"], episode_reward)
        reward_history["average_reward"] = reward_history["total_reward"] / reward_history["episode_count"]
        
        # Log episode summary
        logger.info(f"""
        Episode {reward_history['episode_count']} Summary:
        - Episode Reward: {episode_reward:.2f}
        - Average Reward: {reward_history['average_reward']:.2f}
        - Max Reward: {reward_history['max_reward']:.2f}
        - Min Reward: {reward_history['min_reward']:.2f}
        - Total Reward: {reward_history['total_reward']:.2f}
        - Episode Duration: {reward_history['episode_stats']['episode_duration']} steps
        - Damage Dealt: {reward_history['episode_stats']['damage_dealt']:.2f}
        - Damage Taken: {reward_history['episode_stats']['damage_taken']:.2f}
        - Successful Combos: {reward_history['episode_stats']['successful_combos']}
        - Failed Combos: {reward_history['episode_stats']['failed_combos']}
        - Agent Deaths: {reward_history['episode_stats']['agent_deaths']}
        - Player Deaths: {reward_history['episode_stats']['player_deaths']}
        """)
        
        # Reset episode stats
        reward_history["episode_stats"] = {
            "agent_deaths": 0,
            "player_deaths": 0,
            "episode_duration": 0,
            "damage_dealt": 0,
            "damage_taken": 0,
            "successful_combos": 0,
            "failed_combos": 0
        }
        reward_history["current_episode_reward"] = 0.0
        
        # Save reward history periodically
        if reward_history["episode_count"] % 10 == 0:
            save_reward_history()

def analyze_player_style(distance: float, player_dps: float) -> str:
    """Analyze if player is using melee or ranged style based on current target"""
    # If DPS is high (>15), likely a fighter
    if player_dps > 10:
        return "fighter"
    # If DPS is low (<8), likely a mage
    elif player_dps < 8:
        return "mage"
    # Otherwise balanced
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
    start_time = time.time()
    
    # Log incoming state
    logger.info(f"Received state from Godot: distance={state.distance:.2f}, player_hp={state.player_hp:.2f}, enemy_hp={state.enemy_hp:.2f}")
    
    # Check for episode end conditions
    is_episode_end = False
    if state.enemy_hp <= 0:  # Agent death
        reward_history["episode_stats"]["agent_deaths"] += 1
        is_episode_end = True
    elif state.player_hp <= 0:  # Player death
        reward_history["episode_stats"]["player_deaths"] += 1
        is_episode_end = True
    
    # Analyze player style based on DPS
    player_style = analyze_player_style(state.distance, state.player_dps)
    logger.info(f"Player style analysis: {player_style} (DPS: {state.player_dps})")
    
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
    model_start_time = time.time()
    action, _states = model.predict(obs, deterministic=True)
    model_time = (time.time() - model_start_time) * 1000  # Convert to milliseconds
    predicted_action = actions[int(action)]
    
    # Calculate reward based on state and action
    reward = calculate_reward(state, predicted_action)
    update_reward_history(reward, state, is_episode_end)
    
    # Check for combo opportunities
    last_action = action_history[-1] if action_history else None
    combo_action = get_best_combo(player_style, last_action)
    
    # Force more appropriate actions based on player style and distance
    logger.info(f"""
    Action Selection Debug:
    - Player Style: {player_style}
    - Distance: {state.distance:.2f}
    - Can Summon: {state.can_summon}
    - Can Tornado: {state.can_tornado}
    - Can Full Tornado: {state.can_full_tornado}
    - Combo Action: {combo_action}
    - Current MP: {state.enemy_mp}
    - Current HP: {state.enemy_hp}
    """)

    if player_style == "mage":
        if state.distance < 3.0:  # Danger zone
            logger.info("Mage in danger zone")
            if combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "retreat"
                logger.info("Selected retreat (no skills available)")
        elif state.distance < 5.0:  # Combat zone
            logger.info("Mage in combat zone")
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")
        else:  # Long range
            logger.info("Mage in long range")
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")
    elif player_style == "fighter":
        if state.distance < 3.0:  # Danger zone
            logger.info("Fighter in danger zone")
            if combo_action == "full_tornado" and state.can_full_tornado:
                predicted_action = "full_tornado"
                logger.info("Selected full_tornado (combo)")
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_full_tornado:
                predicted_action = "full_tornado"
                logger.info("Selected full_tornado (available)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "retreat"
                logger.info("Selected retreat (no skills available)")
        elif state.distance < 5.0:  # Combat zone
            logger.info("Fighter in combat zone")
            if combo_action == "full_tornado" and state.can_full_tornado:
                predicted_action = "full_tornado"
                logger.info("Selected full_tornado (combo)")
            elif combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_full_tornado:
                predicted_action = "full_tornado"
                logger.info("Selected full_tornado (available)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")
        else:  # Long range
            logger.info("Fighter in long range")
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")
    else:  # balanced style
        if state.distance < 3.0:  # Danger zone
            logger.info("Balanced in danger zone")
            if combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "retreat"
                logger.info("Selected retreat (no skills available)")
        elif state.distance < 5.0:  # Combat zone
            logger.info("Balanced in combat zone")
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif combo_action == "tornado" and state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (combo)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            elif state.can_tornado:
                predicted_action = "tornado"
                logger.info("Selected tornado (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")
        else:  # Long range
            logger.info("Balanced in long range")
            if combo_action == "summon" and state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (combo)")
            elif state.can_summon:
                predicted_action = "summon"
                logger.info("Selected summon (available)")
            else:
                predicted_action = "chase"
                logger.info("Selected chase (no skills available)")

    logger.info(f"Final selected action: {predicted_action}")
    
    # Update action history
    action_history.append(predicted_action)
    
    # Calculate total processing time
    total_time = (time.time() - start_time) * 1000  # Convert to milliseconds
    
    # Log detailed timing and prediction information
    logger.info(f"""
    Request Processing Details:
    - Total processing time: {total_time:.2f}ms
    - Model prediction time: {model_time:.2f}ms
    - Player Style: {player_style}
    - Distance: {state.distance:.2f}
    - Original Action: {actions[int(action)]}
    - Combo Action: {combo_action}
    - Final Action: {predicted_action}
    - Action History: {list(action_history)}
    - Current Reward: {reward:.2f}
    - Total Reward: {reward_history['total_reward']:.2f}
    - Average Reward: {reward_history['average_reward']:.2f}
    - Episode Duration: {reward_history['episode_stats']['episode_duration']}
    - Damage Dealt: {reward_history['episode_stats']['damage_dealt']:.2f}
    - Damage Taken: {reward_history['episode_stats']['damage_taken']:.2f}
    """)
    
    return {
        "action": predicted_action,
        "player_style": player_style,
        "player_dps": state.player_dps,  # Return DPS instead of melee percentage
        "processing_time_ms": total_time,
        "model_time_ms": model_time,
        "current_reward": reward,
        "total_reward": reward_history["total_reward"],
        "average_reward": reward_history["average_reward"],
        "episode_stats": reward_history["episode_stats"],
        "is_episode_end": is_episode_end
    }

def calculate_reward(state: State, action: str) -> float:
    """Calculate reward based on state and action"""
    reward = 0.0
    
    # Reward for dealing damage
    if state.damage_taken > 0:
        reward += state.damage_taken * 0.5
    
    # Penalty for taking damage
    if state.player_hp < 100:
        reward -= (100 - state.player_hp) * 0.3
    
    # Reward for maintaining good distance
    if 3.0 <= state.distance <= 7.0:
        reward += 0.2
    
    # Penalty for being too close or too far
    if state.distance < 3.0 or state.distance > 7.0:
        reward -= 0.1
    
    # Reward for successful combos
    if action_history and action in combo_success[analyze_player_style(state.distance, state.player_dps)].get(action_history[-1], {}):
        reward += 0.3
    
    # Penalty for running out of MP
    if state.enemy_mp < 20:
        reward -= 0.2
    
    # Large penalty for death
    if state.enemy_hp <= 0:  # Agent death
        reward -= 10.0
    elif state.player_hp <= 0:  # Player death
        reward += 10.0
    
    return reward

@app.post("/end_episode")
async def end_episode():
    """Endpoint to mark the end of an episode"""
    update_reward_history(0.0, is_episode_end=True)
    return {
        "episode_count": reward_history["episode_count"],
        "total_reward": reward_history["total_reward"],
        "average_reward": reward_history["average_reward"],
        "max_reward": reward_history["max_reward"],
        "min_reward": reward_history["min_reward"]
    }

@app.get("/reward_stats")
async def get_reward_stats():
    """Get current reward statistics"""
    return {
        "episode_count": reward_history["episode_count"],
        "total_reward": reward_history["total_reward"],
        "average_reward": reward_history["average_reward"],
        "max_reward": reward_history["max_reward"],
        "min_reward": reward_history["min_reward"],
        "current_episode_reward": reward_history["current_episode_reward"]
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
            "player_dps": drl_result["player_dps"]
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
    logger.info("Starting DRL server...")
    logger.info("Server will be available at http://0.0.0.0:8000")
    import uvicorn
    uvicorn.run("drl_server:app", host="0.0.0.0", port=8000, reload=True)
