from transformers import AutoModel, AutoTokenizer
import numpy as np
import torch

model = AutoModel.from_pretrained("EleutherAI/gpt-neo-2.7B")
tokenizer = AutoTokenizer.from_pretrained("EleutherAI/gpt-neo-2.7B")

sentence = "My name is Clara and I am"
inputs = tokenizer(sentence, return_tensors="pt")["input_ids"]

torch.onnx.export(
    model, 
    inputs,
    "./gpt-neo-2.7b/gpt-neo-2.7b.onnx",
    export_params=True,
)

npz_inputs = {}

npz_inputs["0"] = inputs

np.savez("./gpt-neo-2.7b.npz", **npz_inputs)
print(inputs.shape, inputs.type())
