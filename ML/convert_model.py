import torch
from stable_baselines3 import PPO

model = PPO.load("ppo_wraith")
policy = model.policy

# Example dummy input (match your state shape)
dummy_input = torch.randn(1, 11)  # 11 = your state vector length

# Export to ONNX
torch.onnx.export(
    policy.mlp_extractor.policy_net,  # or policy.actor if using SB3 >=2.0
    dummy_input,
    "ppo_wraith.onnx",
    input_names=["input"],
    output_names=["output"],
    dynamic_axes={"input": {0: "batch_size"}, "output": {0: "batch_size"}},
    opset_version=11
)