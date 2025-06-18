# gym_wraith.py
import gymnasium as gym
from gymnasium import spaces
import numpy as np
import time

class WraithEnv(gym.Env):
    def __init__(self):
        super(WraithEnv, self).__init__()
        
        # Action space: 0=Summon, 1=Tornado, 2=Full Tornado, 3=Retreat, 4=Chase
        self.action_space = spaces.Discrete(5)
        
        # Observation space
        self.observation_space = spaces.Box(
            low=np.array([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            high=np.array([100, 100, 100, 100, 20, 100, 100, 1, 1, 1, 10, 10, 5]),
            dtype=np.float32
        )
        
        # Combo tracking
        self.combo_history = []
        self.last_damage_dealt = 0
        self.player_style_history = []
        self.combo_success = {
            "fighter": {
                "summon": {"tornado": 0, "full_tornado": 0},
                "tornado": {"full_tornado": 0, "retreat": 0},
                "full_tornado": {"retreat": 0, "chase": 0}
            },
            "mage": {
                "summon": {"tornado": 0, "chase": 0},
                "tornado": {"summon": 0, "retreat": 0},
                "retreat": {"summon": 0, "tornado": 0}
            }
        }
        
        # Constants
        self.MELEE_THRESHOLD = 8.0
        self.COMBO_TIMEOUT = 2.0
        self.last_action_time = 0

        # Action mapping
        self.actions = ["summon", "tornado", "full_tornado", "retreat", "chase"]
        
        # Episode tracking
        self.episode_count = 0
        
        # Reset environment
        self.reset()

    def reset(self, seed=None, options=None):
        # Handle seed for reproducibility
        if seed is not None:
            np.random.seed(seed)
            
        self.episode_count += 1
        if self.episode_count % 100 == 0:
            print(f"[Episode {self.episode_count}] Environment Reset.")
        
        # Initialize state
        self.state = np.array([
            np.random.uniform(80, 100),  # enemy_hp
            np.random.uniform(80, 100),  # enemy_mp
            np.random.uniform(80, 100),  # player_hp
            np.random.uniform(80, 100),  # player_mp
            np.random.uniform(5, 20),    # distance
            0,                           # player_dps
            0,                           # damage_taken
            1,                           # can_summon
            1,                           # can_tornado
            1,                           # can_full_tornado
            0,                           # tornado_cd
            0,                           # summon_cd
            0                            # summon_count
        ], dtype=np.float32)
        
        # Reset tracking variables
        self.combo_history = []
        self.last_damage_dealt = 0
        self.player_style_history = []
        self.last_action_time = time.time()
        
        return self.state, {}  # Return observation and info dict

    def step(self, action):
        # Update combo timeout
        current_time = time.time()
        if current_time - self.last_action_time > self.COMBO_TIMEOUT:
            self.combo_history = []
        self.last_action_time = current_time

        # Get current state
        enemy_hp, enemy_mp, player_hp, player_mp, distance, player_dps, damage_taken, \
        can_summon, can_tornado, can_full_tornado, tornado_cd, summon_cd, summon_count = self.state

        # Analyze player style
        is_melee = distance < self.MELEE_THRESHOLD
        self.player_style_history.append(is_melee)
        melee_percentage = sum(self.player_style_history[-50:]) / len(self.player_style_history[-50:])
        
        if melee_percentage > 0.7:
            player_style = "fighter"
        elif melee_percentage < 0.3:
            player_style = "mage"
        else:
            player_style = "balanced"

        # Calculate reward
        reward = 0
        
        # Combo reward
        if len(self.combo_history) > 0:
            last_action = self.combo_history[-1]
            current_action = self.actions[action]
            
            # Check if this is a valid combo
            if player_style in self.combo_success and \
               last_action in self.combo_success[player_style] and \
               current_action in self.combo_success[player_style][last_action]:
                combo_success = self.combo_success[player_style][last_action][current_action]
                reward += combo_success * 0.5  # Bonus for successful combos
        
        # Update combo history
        self.combo_history.append(self.actions[action])
        if len(self.combo_history) > 3:
            self.combo_history.pop(0)
        
        # Action-specific rewards
        if action == 0:  # Summon
            if can_summon:
                reward += 1.0
                if player_style == "mage":
                    reward += 0.5  # Extra reward for summon against mage
            else:
                reward -= 2.0
        elif action == 1:  # Tornado
            if can_tornado:
                reward += 1.0
                if distance < 5.0:
                    reward += 0.5  # Extra reward for close range tornado
            else:
                reward -= 2.0
        elif action == 2:  # Full Tornado
            if can_full_tornado:
                reward += 1.5
                if player_style == "fighter" and distance < 3.0:
                    reward += 1.0  # Extra reward for full tornado against fighter
            else:
                reward -= 2.0
        elif action == 3:  # Retreat
            if distance < 3.0:
                reward += 1.0  # Good retreat
            else:
                reward -= 1.0  # Bad retreat
        elif action == 4:  # Chase
            if distance > 5.0:
                reward += 0.5  # Good chase
            else:
                reward -= 1.0  # Bad chase

        # Penalty for action repetition
        if len(self.combo_history) >= 2 and self.combo_history[-1] == self.combo_history[-2]:
            reward -= 1.0

        # Update state
        self.state = self._get_next_state(action)

        # Check if episode is done
        terminated = enemy_hp <= 0 or player_hp <= 0
        truncated = False  # No truncation in this environment
        
        # Add info dict
        info = {
            "player_style": player_style,
            "melee_percentage": melee_percentage,
            "combo_history": list(self.combo_history),
            "distance": distance
        }
        
        return self.state, reward, terminated, truncated, info

    def _get_next_state(self, action):
        # ... existing state update logic ...
        return self.state

    def render(self):
        print(f"[Step {self.steps}] Enemy HP: {self.enemy_hp:.1f}, MP: {self.enemy_mp:.1f}, Dist: {self.distance:.1f}")
        print(f"Player Type: {self.player_type}, HP: {self.player_hp:.1f}, MP: {self.player_mp:.1f}")