from transformers import BertForSequenceClassification, BertTokenizer
import torch
import numpy as np

# Load the model
model = BertForSequenceClassification.from_pretrained("bert-base-uncased")
with torch.no_grad():
    model.classifier = torch.nn.Identity() # Ensure the model reproducibility as the classifier is always inited differently

# Create dummy input for export
tokenizer = BertTokenizer.from_pretrained("bert-base-uncased")
sentence = "I love AI and privacy!"
inputs = tokenizer(sentence, padding = "max_length", max_length = 8, return_tensors="pt")["input_ids"]

torch.onnx.export(
    model,
    inputs,
    "./tmp/bert_nooptim.onnx",
    export_params=True,
)

npz_inputs = {}

npz_inputs["input.1"] = inputs

np.savez("./bert.npz", **npz_inputs)
print(inputs.shape, inputs.type())
