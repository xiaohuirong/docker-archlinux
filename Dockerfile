FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

LABEL maintainer="hoream@qq.com"

RUN apt update && apt install -y zsh fish sudo vim exa zoxide fzf git python3-pip rsync

RUN useradd -m -s /usr/bin/zsh -p 123456abc arch

# 使用 visudo 来安全地添加规则
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' | EDITOR='tee -a' visudo

COPY ./skel /home/arch

WORKDIR /home/arch
RUN chown -R arch:arch /home/arch

# 复制 entrypoint 脚本并设置权限
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 设置入口点
ENTRYPOINT ["/entrypoint.sh"]

USER arch
CMD ["/bin/zsh"]
