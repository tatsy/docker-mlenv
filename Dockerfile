FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV HOME /root
ENV TERM xterm-256color
SHELL ["/bin/bash", "-c"]

# Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Update APT
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y locales

# Install some packages
RUN apt-get install -y zsh fish git rsync curl wget unzip peco
RUN apt-get install -y build-essential cmake automake ninja-build libtool

# Setup OpenSSH
RUN apt-get install -y openssh-server
RUN sed -ri 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
RUN sed -ri 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/(^\s+SendEnv.+)/#\1/' /etc/ssh/ssh_config
RUN mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh

# Setup for SSH
RUN mkdir -p /run/sshd
RUN mkdir -p /var/run/sshd
EXPOSE 22

# Setup Python
RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:deadsnakes/ppa
RUN apt-get update -y
RUN apt-get install -y python3.9-dev python3.10-dev python3.11-dev python3.12-dev python3-pip
RUN python3 --version
RUN pip3 --version
RUN pip3 install -U pip
RUN pip3 install -U setuptools wheel
RUN pip3 install poetry

# Install NeoVim
RUN apt-get install -y gettext luarocks npm nodejs
RUN git clone https://github.com/neovim/neovim $HOME/neovim --depth 1
RUN cd $HOME/neovim && \
  make CMAKE_BUILD_TYPE=RelWithDebInfo && \
  make install

# Install Visual Studio Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
RUN install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
RUN echo "deb [arch=amd64,amd64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
RUN rm -f packages.microsoft.gpg
RUN apt-get install apt-transport-https
RUN apt-get update
RUN apt-get install -y code

# Some post setting
RUN chsh -s /bin/zsh

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Copy dotfiles
RUN git clone https://github.com/tatsy/dotfiles $HOME/dotfiles
RUN rsync -avzP $HOME/dotfiles/.zshrc $HOME/.zshrc
RUN rsync -avzP $HOME/dotfiles/.vimrc $HOME/.vimrc
RUN mkdir -p $HOME/.config/nvim && \
  rsync -avzP $HOME/dotfiles/.config/nvim/ $HOME/.config/nvim/
RUN mkdir -p $HOME/.config/fish && \
  rsync -avzP $HOME/dotfiles/.config/fish/ $HOME/.config/fish/

# Setup zplug
ENV ZPLUG_HOME $HOME/.zplug
RUN apt-get install fonts-powerline
RUN git clone https://github.com/zplug/zplug $ZPLUG_HOME

# Command
CMD ["/usr/sbin/sshd", "-D"]
