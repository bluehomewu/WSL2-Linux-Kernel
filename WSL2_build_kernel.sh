#!/bin/bash

# 設定顏色
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # 沒有顏色

# 初始化 Kernel 路徑
LINUX_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
echo -e "${GREEN}Kernel 路徑：" $LINUX_DIR ${NC}

# 初始化日期時間 (YYYYMMDD_HHMMSS)
current_date_time="$(date +'%Y%m%d_%H%M%S')"
echo "日期時間：" $current_date_time

# 初始化 Log 檔案
LOG_FILE="Build_WSL2_Kernel_$current_date_time.log"
echo "Log 檔案：" $LOG_FILE
# 嘗試在指定目錄下建立 Log 檔案
touch "$LINUX_DIR/$LOG_FILE"

# 檢查檔案是否建立成功
if [ -f "$LINUX_DIR/$LOG_FILE" ]; then
    echo -e "${GREEN}Log 檔案已成功建立：$LINUX_DIR/$LOG_FILE${NC}" | tee -a $LOG_FILE
else
    echo -e "${RED}無法建立 Log 檔案：$LINUX_DIR/$LOG_FILE${NC}" | tee -a $LOG_FILE
    exit 1
fi

# 安裝編譯 kernel 所需的套件
read -p "是否需要安裝編譯 Kernel 所需的套件？(y/n): " installPKG_choice
echo "是否需要安裝編譯 Kernel 所需的套件？(y/n)" $installPKG_choice >> $LOG_FILE
if [ "$installPKG_choice" == "y" ]; then
    echo -e "${GREEN}正在安裝編譯 Kernel 所需的套件...${NC}" | tee -a $LOG_FILE
    read -s -p "輸入 sudo password:" sudo_password
    echo
    echo $sudo_password | sudo -S apt update
    echo $sudo_password | sudo -S apt install wslu build-essential flex bison dwarves libssl-dev libelf-dev -y
fi

# 提問是否需要執行 make clean
read -p "是否需要執行 make clean? (y/n): " clean_choice
echo "是否需要執行 make clean? (y/n): " $clean_choice | tee -a $LOG_FILE

start_time=$(date +%s)  # 記錄開始時間

echo "正在開始編譯 WSL2 的 Kernel..." | tee -a $LOG_FILE
cd $LINUX_DIR

if [ "$clean_choice" == "y" ]; then
    echo "正在執行 make clean..." | tee -a $LOG_FILE
    make clean -j$(nproc) | tee -a $LOG_FILE
fi

# 初始化 defconfig 檔案
defconfig_file="arch/x86/configs/Edward_config-wsl"

# 編譯 kernel
make KCONFIG_CONFIG=$defconfig_file -j$(nproc) | tee -a $LOG_FILE

cd -

end_time=$(date +%s)  # 記錄結束時間
elapsed=$((end_time - start_time))  # 計算總耗時
minutes=$((elapsed / 60))
seconds=$((elapsed % 60))
echo "編譯完成，總耗時: ${minutes}分鐘 ${seconds}秒" | tee -a $LOG_FILE

# 輸出 kernel 的版本號
echo -e "${RED}Kernel 版本號: $(cat $LINUX_DIR/include/config/kernel.release)${NC}" | tee -a $LOG_FILE

read -p "是否要安裝 kernel? (y/n): " install_choice
echo "是否要安裝 kernel? (y/n): $install_choice" >> "$LOG_FILE"

# 讀取 Windows User home directory
USER_HOME=$(wslpath "$(wslvar USERPROFILE)")
echo "Windows 使用者家目錄: $USER_HOME" | tee -a $LOG_FILE

if [ "$install_choice" == "y" ]; then
    read -s -p "輸入 sudo password:" sudo_password
    echo
    echo -e "${RED}開始安裝 Kernel...${NC}" | tee -a $LOG_FILE
    echo $sudo_password | sudo -S make modules_install -j$(nproc) 2>&1 | tee -a $LOG_FILE
    echo $sudo_password | sudo -S make install -j$(nproc) 2>&1 | tee -a $LOG_FILE
    echo $sudo_password | sudo -S cp -rf $LINUX_DIR/vmlinux $USER_HOME 2>&1 | tee -a $LOG_FILE
    echo -e "${GREEN}Kernel 安裝完成${NC}" | tee -a $LOG_FILE
fi

exit 0
