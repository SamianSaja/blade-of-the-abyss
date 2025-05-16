import gymnasium as gym
from gymnasium import spaces
import numpy as np

class WraithEnv(gym.Env):
    def __init__(self):
        super().__init__()

        self.observation_space = spaces.Box(low=0, high=200, shape=(12,), dtype=np.float32)
        self.action_space = spaces.Discrete(5)  # 0=summon, 1=tornado, 2=attack, 3=retreat, 4=chase

        # Constants
        self.MAX_HP = 100
        self.MAX_MP = 100
        self.TORNADO_COST = 20
        self.SUMMON_COST = 30
        self.ATTACK_COST = 10
        self.TORNADO_COOLDOWN = 5
        self.SUMMON_COOLDOWN = 10
        self.MAX_SUMMONS = 3

        self.reset()

    def reset(self, seed=None, options=None):
        self.enemy_hp = self.MAX_HP
        self.enemy_mp = self.MAX_MP
        self.player_hp = self.MAX_HP
        self.player_mp = self.MAX_MP
        self.distance = np.random.uniform(5, 20)
        self.player_dps = np.random.uniform(3, 10)

        self.summon_cd = 0
        self.tornado_cd = 0
        self.summon_count = 0
        self.damage_taken = 0

        self.steps = 0
        return self._get_obs(), {}

    def step(self, action):
        reward = 0
        done = False
        info = {}

        self.summon_cd = max(0, self.summon_cd - 1)
        self.tornado_cd = max(0, self.tornado_cd - 1)
        self.steps += 1

        can_summon = self.enemy_mp >= self.SUMMON_COST and self.summon_count < self.MAX_SUMMONS and self.summon_cd == 0
        can_tornado = self.enemy_mp >= self.TORNADO_COST and self.tornado_cd == 0 and self.distance <= 10

        # Action effects
        if action == 0:  # Summon
            if can_summon:
                reward += 2.0
                self.enemy_mp -= self.SUMMON_COST
                self.summon_count += 1
                self.summon_cd = self.SUMMON_COOLDOWN
            else:
                reward -= 1.0
        elif action == 1:  # Tornado
            if can_tornado:
                reward += 2.5
                self.enemy_mp -= self.TORNADO_COST
                self.player_hp -= np.random.randint(5, 10)
                self.tornado_cd = self.TORNADO_COOLDOWN
            else:
                reward -= 1.2
        elif action == 2:  # Attack
            if self.enemy_mp >= self.ATTACK_COST and self.distance <= 12:
                reward += 1.0
                self.enemy_mp -= self.ATTACK_COST
                self.player_hp -= np.random.randint(4, 8)
            else:
                reward -= 0.5
        elif action == 3:  # Retreat
            if self.distance < 8 or self.enemy_hp < 30:
                reward += 1.0
                self.distance += np.random.uniform(1.0, 3.0)
            else:
                reward -= 0.2
        elif action == 4:  # Chase
            if self.distance > 12:
                reward += 0.8
                self.distance -= np.random.uniform(1.0, 2.0)
            else:
                reward -= 0.3

        # Player attacks back (with evasion logic)
        if action == 3:  # retreat
            damage = (self.player_dps * 0.5) + np.random.uniform(0, 2)
        elif action == 4:  # chase
            damage = (self.player_dps * 0.8) + np.random.uniform(0, 2.5)
        else:
            damage = self.player_dps + np.random.uniform(0, 3)

        self.enemy_hp -= damage
        self.damage_taken += damage

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
            self.player_dps,
            self.damage_taken,
            float(self.enemy_mp >= self.SUMMON_COST and self.summon_count < self.MAX_SUMMONS and self.summon_cd == 0),
            float(self.enemy_mp >= self.TORNADO_COST and self.tornado_cd == 0 and self.distance <= 10),
            self.summon_count,
            self.tornado_cd,
            self.summon_cd
        ], dtype=np.float32)

    def render(self):
        print(f"[Step {self.steps}] HP: {self.enemy_hp:.1f}, MP: {self.enemy_mp:.1f}, Dist: {self.distance:.1f}")
