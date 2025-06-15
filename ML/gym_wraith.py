# gym_wraith.py
import gymnasium as gym
from gymnasium import spaces
import numpy as np

class WraithEnv(gym.Env):
    def __init__(self):
        super().__init__()
        self.episode_count = 0

        # Match Godot's observation space
        self.observation_space = spaces.Box(low=0, high=500, shape=(13,), dtype=np.float32)
        self.action_space = spaces.Discrete(5)  # 0=summon, 1=tornado, 2=full tornado, 3=retreat, 4=chase

        # Match Godot's constants
        self.MAX_HP = 300
        self.MAX_MP = 500
        self.TORNADO_COST = 5
        self.SUMMON_COST = 20
        self.MAX_SUMMONS = 3
        self.TORNADO_COOLDOWN = 8
        self.SUMMON_COOLDOWN = 6
        self.FULL_TORNADO_COOLDOWN = 16
        self.ATTACK_RANGE = 10.0
        self.STOP_DISTANCE = 8.0

        # Action repetition tracking
        self.last_action = None
        self.action_repeat_count = 0
        self.action_history = []
        self.max_action_history = 10

        # Player type tracking
        self.player_type = None  # Will be set to 'fighter' or 'mage'
        self.player_style_weights = {
            'fighter': {'melee': 0.8, 'ranged': 0.2},
            'mage': {'melee': 0.2, 'ranged': 0.8}
        }

        self.reset()

    def reset(self, seed=None, options=None):
        self.episode_count += 1
        if self.episode_count % 100 == 0:
            print(f"[Episode {self.episode_count}] Environment Reset.")
        
        # Initialize state
        self.enemy_hp = self.MAX_HP
        self.enemy_mp = self.MAX_MP
        self.player_hp = self.MAX_HP
        self.player_mp = self.MAX_MP
        self.distance = np.random.uniform(5, 20)

        # Cooldowns and counters
        self.summon_cd = 0
        self.tornado_cd = 0
        self.full_tornado_cd = 0
        self.summon_count = 0
        self.damage_taken = 0
        self.steps = 0

        # Reset action tracking
        self.last_action = None
        self.action_repeat_count = 0

        # Randomly determine player type at start of episode
        self.player_type = np.random.choice(['fighter', 'mage'])
        print(f"Player type: {self.player_type}")

        return self._get_obs(), {}

    def step(self, action):
        reward = 0
        done = False
        info = {}

        # Update action history
        self.action_history.append(action)
        if len(self.action_history) > self.max_action_history:
            self.action_history.pop(0)

        # Calculate action diversity penalty
        action_counts = {}
        for a in self.action_history:
            action_counts[a] = action_counts.get(a, 0) + 1
        
        # Penalize if any action is used more than 40% of the time
        for count in action_counts.values():
            if count / len(self.action_history) > 0.4:
                reward -= 2.0

        # Check for action repetition
        if action == self.last_action:
            self.action_repeat_count += 1
            if self.action_repeat_count > 2:
                reward -= 3.0  # Increased penalty for repetition
        else:
            self.action_repeat_count = 1
            self.last_action = action

        # Update cooldowns
        self.summon_cd = max(0, self.summon_cd - 1)
        self.tornado_cd = max(0, self.tornado_cd - 1)
        self.full_tornado_cd = max(0, self.full_tornado_cd - 1)
        self.steps += 1

        # Check action availability
        can_summon = self.enemy_mp >= self.SUMMON_COST and self.summon_count < self.MAX_SUMMONS and self.summon_cd == 0
        can_tornado = self.enemy_mp >= self.TORNADO_COST and self.tornado_cd == 0 and self.distance <= self.ATTACK_RANGE
        can_full_tornado = self.enemy_mp >= self.TORNADO_COST and self.full_tornado_cd == 0 and self.distance < 5

        # Execute action with enhanced rewards
        if action == 0:  # Summon
            if can_summon:
                reward += 2.0
                self.enemy_mp -= self.SUMMON_COST
                self.summon_count += 1
                self.summon_cd = self.SUMMON_COOLDOWN
            else:
                reward -= 2.0  # Increased penalty for invalid action
        elif action == 1:  # Tornado
            if can_tornado:
                reward += 2.5
                self.enemy_mp -= self.TORNADO_COST
                self.player_hp -= np.random.randint(15, 25)
                self.tornado_cd = self.TORNADO_COOLDOWN
            else:
                reward -= 2.0
        elif action == 2:  # Full Tornado
            if can_full_tornado:
                reward += 3.0
                self.enemy_mp -= self.TORNADO_COST
                self.player_hp -= np.random.randint(20, 30)
                self.full_tornado_cd = self.FULL_TORNADO_COOLDOWN
            else:
                reward -= 2.0
        elif action == 3:  # Retreat
            if self.distance < self.STOP_DISTANCE or self.enemy_hp < 30:
                reward += 1.0
                self.distance += np.random.uniform(1.0, 3.0)
            else:
                reward -= 1.0  # Increased penalty for unnecessary retreat
        elif action == 4:  # Chase
            if self.distance > self.ATTACK_RANGE:
                reward += 0.8
                self.distance -= np.random.uniform(1.0, 2.0)
            else:
                reward -= 1.0  # Increased penalty for unnecessary chase

        # Add state validation logging
        if self.episode_count % 100 == 0:
            print(f"State validation - Distance: {self.distance:.2f}, HP: {self.enemy_hp:.2f}, MP: {self.enemy_mp:.2f}")
            print(f"Action history: {self.action_history}")
            print(f"Action counts: {action_counts}")

        # Player Behavior Simulation based on type
        player_style = self.player_type
        style_weights = self.player_style_weights[player_style]

        # Determine if player uses melee or ranged attack based on their type
        is_melee = np.random.random() < style_weights['melee']
        
        if is_melee:
            if self.distance < 5:
                damage = np.random.uniform(8, 15)
                mp_cost = np.random.uniform(0, 3)
            else:
                damage = np.random.uniform(3, 6)
                mp_cost = np.random.uniform(0, 3)
        else:  # ranged
            if self.distance > 8:
                damage = np.random.uniform(5, 12)
                mp_cost = np.random.uniform(5, 10)
            else:
                damage = np.random.uniform(2, 5)
                mp_cost = np.random.uniform(5, 10)

        self.enemy_hp -= damage
        self.damage_taken += damage
        self.player_mp = max(0, self.player_mp - mp_cost)

        # Adaptive rewards based on player type
        if player_style == 'mage':
            if action == 1 or action == 4:  # Tornado or Chase
                reward += 1.0  # Good against mage
            elif action == 3:  # Retreat
                reward -= 0.5  # Bad against mage
        elif player_style == 'fighter':
            if action == 2 or action == 3:  # Full Tornado or Retreat
                reward += 1.0  # Good against fighter
            elif action == 4:  # Chase
                reward -= 0.5  # Bad against fighter

        # Check for episode end
        if self.enemy_hp <= 0 or self.player_hp <= 0:
            done = True
            reward += 5 if self.player_hp <= 0 else -5

        return self._get_obs(), reward, done, False, info

    def _get_obs(self):
        return np.array([
            self.enemy_hp,
            self.enemy_mp,
            self.player_hp,
            self.player_mp,
            self.distance,
            float(self.player_type == 'fighter'),  # Player type indicator
            self.damage_taken,
            float(self.enemy_mp >= self.SUMMON_COST and self.summon_count < self.MAX_SUMMONS and self.summon_cd == 0),
            float(self.enemy_mp >= self.TORNADO_COST and self.tornado_cd == 0 and self.distance <= self.ATTACK_RANGE),
            float(self.enemy_mp >= self.TORNADO_COST and self.full_tornado_cd == 0 and self.distance < 5),
            self.tornado_cd,
            self.summon_cd,
            self.summon_count
        ], dtype=np.float32)

    def render(self):
        print(f"[Step {self.steps}] Enemy HP: {self.enemy_hp:.1f}, MP: {self.enemy_mp:.1f}, Dist: {self.distance:.1f}")
        print(f"Player Type: {self.player_type}, HP: {self.player_hp:.1f}, MP: {self.player_mp:.1f}")