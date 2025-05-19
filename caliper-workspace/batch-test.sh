#!/bin/bash

# 定义输出文件
RESULT_LOG="./日志输出.log"
TEST_RESULTS="./最终结果.log"

# 检查并删除已有的日志文件
[ -f "$RESULT_LOG" ] && rm "$RESULT_LOG"
[ -f "$TEST_RESULTS" ] && rm "$TEST_RESULTS"

# 获取用户传入的执行次数参数，默认为 5
RUN_COUNT=5
RELOAD=false

# 解析参数
for arg in "$@"
do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then
        RUN_COUNT=$arg
    elif [[ "$arg" == "--reload" ]]; then
        RELOAD=true
    fi
done

# 如果传入 --reload，执行网络重启逻辑
if [ "$RELOAD" = true ]; then
    cd ..
    # 启动网络
    RED='\033[0;31m'  # 红色
    NC='\033[0m'      # 无颜色（重置）
    echo -e "${RED}关闭网络${NC}"
    ./network.sh down
    echo -e "${RED}启动网络${NC}"
    ./network.sh up
    echo -e "${RED}创建通道${NC}"
    ./network.sh createChannel -c domain1channel
    echo -e "${RED}部署链码${NC}"
    ./network.sh deployCC -c domain1channel -ccn mdh -ccp ./chaincode -ccl go
    cd caliper-workspace
fi

# 重定向标准输出到 result.log
for ((i=1; i<=RUN_COUNT; i++))
do
    echo "Running test #$i"
    npx caliper launch manager \
        --caliper-workspace ./ \
        --caliper-networkconfig networks/fabric-network-domain1.yaml \
        --caliper-benchconfig benchmarks/batch-test-1.yaml \
        --caliper-flow-only-test \
        --caliper-bind-sut fabric:2.5 >> "$RESULT_LOG" 2>/dev/null
done

# 使用 awk 提取从 "### All test results ###" 开始的行，并包含后续 32 行
awk '/### All test results ###/ {count=200} count {print; count--}' "$RESULT_LOG" > "$TEST_RESULTS"

echo "Test results saved to $TEST_RESULTS"