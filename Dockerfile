FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ARG USER_ID=1000
ARG GROUP_ID=1000
ENV HOME=/root
ENV TERM=xterm-256color
SHELL ["/bin/bash", "-c"]

# Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Update APT
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y locales

# Install some packages
RUN apt-get install -y \
    software-properties-common \
    zsh fish git rsync curl wget unzip peco \
    build-essential cmake automake ninja-build libtool \
    openssh-server apt-transport-https \
    gettext luarocks npm nodejs cargo && \
    rm -rf /var/lib/apt/lists/*

# Setup OpenSSH
RUN sed -ri 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -ri 's/(^\s+SendEnv.+)/#\1/' /etc/ssh/ssh_config
RUN mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh

# Setup for SSH
RUN mkdir -p /run/sshd && \
    mkdir -p /var/run/sshd
EXPOSE 22

# Setup Python
RUN apt-add-repository -y ppa:deadsnakes/ppa && \
    apt-get update -y && \
    apt-get install -y \
    python3.9-dev \
    python3.10-dev \
    python3.11-dev \
    python3.12-dev \
    python3-pip
RUN pip3 install -U pip setuptools wheel poetry uv

# Install NeoVim
RUN git clone --branch stable --depth 1 https://github.com/neovim/neovim $HOME/neovim
RUN cd $HOME/neovim && \
  make CMAKE_BUILD_TYPE=RelWithDebInfo && \
  make install

# Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor > packages.microsoft.gpg
RUN install -D -o root -g root -m 644 packages.microsoft.gpg \
    /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,amd64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    tee /etc/apt/sources.list.d/vscode.list > /dev/null
RUN rm -f packages.microsoft.gpg
RUN apt-get update -y && \
    apt-get install -y code

# Some post setting
RUN chsh -s /bin/zsh

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create a user
RUN apt-get install -y sudo
RUN groupadd -g $GROUP_ID user && \
    useradd -ms /usr/bin/zsh -g $GROUP_ID -u $USER_ID user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV HOME=/home/user
USER user

# Sheldon
RUN cargo install sheldon@0.8.0 starship@1.20.1 --locked

# Copy dotfiles
RUN git clone --depth 1 https://github.com/tatsy/dotfiles $HOME/dotfiles && \
    rsync -avzP $HOME/dotfiles/.zshrc $HOME/.zshrc && \
    rsync -avzP $HOME/dotfiles/.config/ $HOME/.config/ && \
    rsync -avzP $HOME/dotfiles/.vimrc $HOME/.vimrc
RUN mkdir -p $HOME/.config/nvim && \
    rsync -avzP $HOME/dotfiles/.config/nvim/ $HOME/.config/nvim/
RUN mkdir -p $HOME/.config/fish && \
    rsync -avzP $HOME/dotfiles/.config/fish/ $HOME/.config/fish/

# Command
WORKDIR /home/user/dev
CMD ["/usr/bin/zsh", "-c"]
