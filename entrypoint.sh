#!/bin/bash
set -e

USER_ID=${USER_ID:-1000}
GROUP_ID=${GROUP_ID:-1000}
USER_NAME=${USER_NAME:-user}

echo "=== 容器启动配置 ==="
echo "目标用户: $USER_NAME (UID: $USER_ID, GID: $GROUP_ID)"

# 检查用户是否已存在
if id "$USER_ID" &>/dev/null; then
    # 用户已存在，获取用户名
    EXISTING_USER=$(getent passwd $USER_ID | cut -d: -f1)
    echo "用户已存在: $EXISTING_USER (UID: $USER_ID)"
    USER_NAME="$EXISTING_USER"
    USER_HOME=$(getent passwd $USER_ID | cut -d: -f6)
else
    # 用户不存在，创建新用户
    echo "创建新用户: $USER_NAME"
    
    # 检查用户名是否已被使用
    if getent passwd "$USER_NAME" &>/dev/null; then
        echo "警告: 用户名 $USER_NAME 已被使用，创建临时用户名"
        USER_NAME="user${USER_ID}"
    fi
    
    # 创建组（如果不存在）
    if ! getent group "$GROUP_ID" &>/dev/null; then
        groupadd -g "$GROUP_ID" "$USER_NAME"
    fi
    
    # 创建用户
    useradd -u "$USER_ID" -g "$GROUP_ID" -m -s /usr/bin/zsh "$USER_NAME"
    
    USER_HOME="/home/$USER_NAME"
    
    # 拷贝配置
    if [ -d "/home/arch" ]; then
        echo "从模板拷贝配置文件..."
        cp -r /home/arch/. "$USER_HOME"/ 2>/dev/null || true
        chown -R "$USER_ID:$GROUP_ID" "$USER_HOME"
        chmod 700 "$USER_HOME"
    fi
fi

# 设置环境变量
export HOME="$USER_HOME"
export USER="$USER_NAME"

# 切换到用户家目录
cd "$HOME"

# 确保 zsh 配置文件存在
if [ ! -f "$HOME/.zshrc" ]; then
    echo "创建默认 zsh 配置..."
    # 生成默认 zsh 配置
    zsh -c "exit" 2>/dev/null || true
fi

echo "=== 启动完成 ==="
echo "当前用户: $USER_NAME"
echo "家目录: $HOME"
echo "工作目录: $(pwd)"

# 切换到目标用户执行命令，保持环境变量
exec sudo -E -u "$USER_NAME" env HOME="$HOME" USER="$USER_NAME" "$@"
