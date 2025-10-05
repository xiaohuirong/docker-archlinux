#!/bin/bash
set -e

# 获取环境变量中的 UID 和 GID，默认为 arch 用户的 ID
USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
USER_NAME=${USER_NAME:-appuser}

# 检查是否启用家目录配置拷贝（默认启用）
COPY_HOME_CONFIG=${COPY_HOME_CONFIG:-true}
ARCH_HOME_SOURCE=${ARCH_HOME_SOURCE:-/home/arch}

echo "=== 容器启动配置 ==="
echo "用户: $USER_NAME (UID: $USER_ID, GID: $GROUP_ID)"
echo "源配置目录: $ARCH_HOME_SOURCE"

# 如果用户 ID 不是 1000（arch 用户），则需要创建新用户
if [ "$USER_ID" != "1000" ]; then
    echo "创建新用户: $USER_NAME (UID: $USER_ID, GID: $GROUP_ID)"
    
    # 删除已存在的用户（如果冲突）
    if getent passwd $USER_ID >/dev/null; then
        existing_user=$(getent passwd $USER_ID | cut -d: -f1)
        if [ "$existing_user" != "$USER_NAME" ]; then
            userdel -f $existing_user || true
        fi
    fi

    if getent group $GROUP_ID >/dev/null; then
        existing_group=$(getent group $GROUP_ID | cut -d: -f1)
        if [ "$existing_group" != "$USER_NAME" ]; then
            groupdel -f $existing_group || true
        fi
    fi

    # 创建新用户和组
    groupadd -g $GROUP_ID $USER_NAME
    useradd -u $USER_ID -g $GROUP_ID -m -s /usr/bin/zsh $USER_NAME
    
    # 添加用户到 sudoers（无密码）
    echo '$USER_NAME ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    
    USER_HOME="/home/$USER_NAME"
else
    echo "使用默认 arch 用户"
    USER_NAME="arch"
    USER_HOME="/home/arch"
fi

# 拷贝 /home/arch 配置到新用户家目录
if [ "$COPY_HOME_CONFIG" = "true" ] && [ -d "$ARCH_HOME_SOURCE" ] && [ "$USER_ID" != "1000" ]; then
    echo "正在从 $ARCH_HOME_SOURCE 拷贝配置文件到 $USER_HOME..."
    
    # 确保目标目录存在且为空
    mkdir -p "$USER_HOME"
    rm -rf "$USER_HOME"/.* "$USER_HOME"/* 2>/dev/null || true
    
    # 使用 rsync 拷贝，保持权限并排除特定文件
    if command -v rsync >/dev/null 2>&1; then
        rsync -av \
            --exclude='.cache' \
            --exclude='.local/share/Trash' \
            --exclude='.npm' \
            --exclude='.yarn' \
            --exclude='.m2/repository' \
            --exclude='.gradle/caches' \
            --exclude='.docker' \
            --exclude='.config/google-chrome' \
            "$ARCH_HOME_SOURCE"/ "$USER_HOME"/
    else
        echo "警告: rsync 不可用，使用 cp 命令"
        cp -r "$ARCH_HOME_SOURCE"/. "$USER_HOME"/ 2>/dev/null || true
    fi
    
    # 修复文件属主
    chown -R $USER_ID:$GROUP_ID "$USER_HOME"
    
    # 设置正确的权限
    chmod 700 "$USER_HOME"
    find "$USER_HOME" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    echo "家目录配置拷贝完成"
else
    echo "跳过家目录配置拷贝"
fi

# 设置环境变量
export HOME="$USER_HOME"
export USER="$USER_NAME"
cd "$HOME"

echo "=== 启动完成 ==="
echo "当前用户: $USER_NAME"
echo "工作目录: $(pwd)"
echo "执行命令: $@"

# 切换到对应用户执行命令
exec sudo -E -u $USER_NAME "$@"
