## onnxruntime benchmarks

import numpy as np
import time
import sys

import os
# set environment variables for singlethread before import onnxruntime
os.environ["OMP_NUM_THREADS"] = "1"

import onnxruntime as rt

# Adjust session options
opts = rt.SessionOptions()
opts.intra_op_num_threads = 1
opts.inter_op_num_threads = 1
opts.execution_mode = rt.ExecutionMode.ORT_SEQUENTIAL

os.environ["OMP_WAIT_POLICY"] = "PASSIVE"

_, model_path, npz_path, nb_of_repeats_per_sample, nb_of_samples = sys.argv

nb_of_samples = int(nb_of_samples)
nb_of_repeats_per_sample = int(nb_of_repeats_per_sample)

sess = rt.InferenceSession(model_path, providers=rt.get_available_providers(), sess_options=opts)

inputs = dict(np.load(npz_path))

results = []

for i in range(nb_of_samples):
    total = 0
    for _ in range(nb_of_repeats_per_sample):
        start = time.time()
        res = sess.run(None, inputs)
        diff = time.time() - start
        total += diff
    sample_time = total / nb_of_repeats_per_sample
    results.append(sample_time)
    print(f"bench (sample {i}/{nb_of_samples}): {sample_time}us/iter, {nb_of_repeats_per_sample} iter")

mean = sum(results) / nb_of_samples
variance = np.var(results)

mean = np.mean(results)
variance = np.var(results)
std_deviation = np.std(results)

print(f"Mean {mean * 1000}")
print(f"Variance {variance * 1000}")
print(f"Std deviation {std_deviation * 1000}")