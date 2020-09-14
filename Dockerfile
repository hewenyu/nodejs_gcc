# Update the VARIANT arg in devcontainer.json to pick a Node.js version: 14, 12, 10 
FROM node

# Options for setup scripts
ARG INSTALL_ZSH="true"
ARG UPGRADE_PACKAGES="true"
ARG USERNAME=node
ARG USER_UID=1000
ARG USER_GID=$USER_UID

ENV NVM_DIR=/usr/local/share/nvm
ENV NVM_SYMLINK_CURRENT=true \ 
    PATH=${NVM_DIR}/current/bin:${PATH}

# 安装所需的软件包并设置非root用户。使用单独的RUN语句添加依赖项
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    # 由于https://security-tracker.debian.org/tracker/CVE-2019-10131删除imagemagick
    && apt-get purge -y imagemagick imagemagick-6-common \
    # 安装软件包，非root用户
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" \
    # Update yarn and install nvm
    && rm -rf /opt/yarn-* /usr/local/bin/yarn /usr/local/bin/yarnpkg \
    && /bin/bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "none" "${USERNAME}" \
    # Clean up
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /root/.gnupg /tmp/library-scripts

# Configure global npm install location
ARG NPM_GLOBAL=/usr/local/share/npm-global
ENV PATH=${PATH}:${NPM_GLOBAL}/bin
RUN mkdir -p ${NPM_GLOBAL} \
    && chown ${USERNAME}:root ${NPM_GLOBAL} \
    && npm config -g set prefix ${NPM_GLOBAL} \
    && sudo -u ${USERNAME} npm config -g set prefix ${NPM_GLOBAL} \
    && echo "if [ \"\$(stat -c '%U' ${NPM_GLOBAL})\" != \"${USERNAME}\" ]; then sudo chown -R ${USER_UID}:root ${NPM_GLOBAL} ${NVM_DIR}; fi" \
    | tee -a /root/.bashrc /root/.zshrc /home/${USERNAME}/.bashrc >> /home/${USERNAME}/.zshrc

# Install eslint globally
RUN sudo -u ${USERNAME} npm install -g eslint

# [Optional] Uncomment this section to install additional OS packages.