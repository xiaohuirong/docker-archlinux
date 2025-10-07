FROM archlinux:latest

LABEL maintainer="hoream@qq.com"

COPY ./config/airootfs/etc/pacman.conf /etc/pacman.conf
COPY ./config/airootfs/etc/pacman.d /etc/pacman.d

RUN pacman -Syu --noconfirm && pacman -S --noconfirm zsh vim sudo wget curl git fish atuin fzf openssh eza zoxide

RUN useradd -m -s /usr/bin/zsh -p 123456abc arch
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' | EDITOR='tee -a' visudo
COPY ./config/airootfs/etc/skel /home/arch
WORKDIR /home/arch
SHELL ["/bin/bash", "-c"]
RUN mkdir -p /home/arch/.cache/vim/{backup,swap,undo}
RUN chown -R arch:arch /home/arch && \
    chmod 700 /home/arch

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/zsh"]
