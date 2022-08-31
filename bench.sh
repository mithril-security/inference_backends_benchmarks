#!/bin/bash
set -e

### Utility Functions

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

git_commit() {
    echo "git rev-parse HEAD"
}

cpu_vendor () {
    lscpu | grep Vendor | awk '{print $NF}'
}

cpu_brand () {
    lscpu | sed -nr '/Model name/ s/.*:\s*(.*) @ .*/\1/p'
}

cpu_features () {
    features=""
    for flag in fma avx2 avx512f; do
        lscpu | grep Flags | grep $flag &> /dev/null
        if [ $? -eq 0 ]
        then
            features+="$flag: true; "
        else
            features+="$flag: false; "
        fi
    done
    echo $features
}

model_hash () {
    sha1sum $1 | awk '{print $1}'
}

onnxruntime_version () {
    cat models/requirements.txt | grep 'onnxruntime==.*\..*\.*' | sed 's/onnxruntime==//'
}

record_results () {
    output=''
    while read line; do
        echo $line
        output+=$"${line}\n"
    done
    record=''
    record+="$(echo -e $output | grep Mean | awk '{print $NF}'), "
    record+="$(echo -e $output | grep 'Std deviation' | awk '{print $NF}'),"
    echo -n "$record " >> $1
}

### Setup Variables

TRACT_VERSION='0.17.2-pre'

REPEATS=3
SAMPLES=50
TOTAL=$(($REPEATS*$SAMPLES))

declare -A MODEL_TO_ONNX_FILE

# ONNX Models:
#  add a script in ./models/{model}_setup.sh to add a model
#  and add a MODEL_TO_ONNX_FILE entry to the onnx file
MODELS=${1:-"bert,wav2vec2,facenet,yolov5s,yolov5n6,gpt2_text_gen"}
MODELS=$(echo $MODELS | tr ',' '\n')

MODEL_TO_ONNX_FILE["bert"]="./models/bert.onnx"
MODEL_TO_ONNX_FILE["wav2vec2"]="./models/wav2vec2.onnx"
MODEL_TO_ONNX_FILE["facenet"]="./models/facenet.onnx"
MODEL_TO_ONNX_FILE["yolov5s"]="./models/yolov5s.onnx"
MODEL_TO_ONNX_FILE["gpt-neo-2.7b"]="./models/gpt-neo-2.7b/gpt-neo-2.7b.onnx"
MODEL_TO_ONNX_FILE["st-gcn"]="./models/st-gcn.onnx"
MODEL_TO_ONNX_FILE["yolov5n6"]="./models/yolov5n6.onnx"
MODEL_TO_ONNX_FILE["gpt2_text_gen"]="./models/gpt2_text_gen.onnx"

echo Testing models: $MODELS

echo Setting up models.

for MODEL in $MODELS; do
    echo Setup model $MODEL
    (cd models; bash ${MODEL}_setup.sh)
done

echo Launching benchmarks.

CSV_PATH=bench.csv
if [ ! -f $CSV_PATH ]; then
    echo 'Commit_Hash, Date, CPU_Vendor, CPU_Brand, CPU_Features, Model_Name, Model_Hash, Tract_Version, Tract_plain_Mean_Time, Tract_Plain_Std_Deviation, Tract_SGX_Mean_time, Tract_SGX_Std_Deviation, Onnxruntime_Version, Onnxruntime_Mean_Time, Onnxruntime_Std_Deviation, Samples, Repeats_Per_Sample, Total_Runs_Per_Backend' > $CSV_PATH
fi
for MODEL in $MODELS; do
    echo -n "'$(git_commit)', '$(timestamp)', '$(cpu_vendor)', '$(cpu_brand)', '$(cpu_features)', '$MODEL', '$(model_hash ${MODEL_TO_ONNX_FILE[$MODEL]})', 'tract-$TRACT_VERSION', " >> $CSV_PATH
    for MODE in plain sgx; do
        echo "Launching model $MODEL with tract in mode $MODE"
        ./bin/app $MODE ${MODEL_TO_ONNX_FILE[$MODEL]} ./models/$MODEL.npz $REPEATS $SAMPLES | record_results $CSV_PATH
        echo "done"
    done
    echo -n "'onnxruntime-$(onnxruntime_version)', " >> $CSV_PATH
    echo "Launching model $MODEL with onnxruntime"
    python ort_bench.py ${MODEL_TO_ONNX_FILE[$MODEL]} ./models/$MODEL.npz $REPEATS $SAMPLES | record_results $CSV_PATH
    echo "done"
    echo "$SAMPLES, $REPEATS, $TOTAL" >> $CSV_PATH
done

echo "run completed successfully, your results are saved in $CSV_PATH"
