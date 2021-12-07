# Note: You can use any Debian/Ubuntu based image you want. 
FROM mcr.microsoft.com/vscode/devcontainers/base:0-bullseye

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"
# [Option] Enable non-root Docker access in container
ARG ENABLE_NONROOT_DOCKER="false"
# [Option] Use the OSS Moby Engine instead of the licensed Docker Engine
ARG USE_MOBY="false"
# Git configuation for commit
ARG GIT_USERMAIL="puglao@cloudemo.site"
ARG GIT_USERNAME="Pug Lao"
# CPU arch
ARG TERRAFORM_ARC="arm64"
ARG TERRAGRUNT_ARC="arm64"
ARG TERRAGRUNT_VER
ARG AWSCLI_ARC="aarch64"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your
# own dependencies. A user of "automatic" attempts to reuse an user ID if one already exists.
ARG USERNAME=automatic
ARG USER_UID=1000
ARG USER_GID=$USER_UID
COPY library-scripts/*.sh /tmp/library-scripts/
RUN apt-get update \
    && /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts/

# Install Terraform latest version
RUN release_url="https://github.com/hashicorp/terraform/releases" \
    && target_version=$(curl -s $release_url | grep -E 'href="/hashicorp/terraform/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+"' | sed -E 's/.*\/hashicorp\/terraform\/releases\/tag\/v([0-9\.]+)".*/\1/g' | head -1) \
    && curl -s "https://releases.hashicorp.com/terraform/${target_version}/terraform_${target_version}_linux_${TERRAFORM_ARC}.zip" -o terraform.zip
RUN unzip terraform.zip -d /usr/bin/
RUN chmod +x /usr/bin/terraform

# Install Terragrunt latest version
RUN release_url='https://github.com/gruntwork-io/terragrunt/releases' \
    && latest_version=$(curl -s $release_url | grep 'href="/gruntwork-io/terragrunt/releases/tag/' | sed -E 's/^.*\/gruntwork-io\/terragrunt\/releases\/tag\/(v[0-9]+\.[0-9]+\.[0-9]+).*$/\1/g' | head -1) \
    && target_version=${TERRAGRUNT_VER:-$latest_version} \
    && curl -sL "${release_url}/download/${target_version}/terragrunt_linux_${TERRAGRUNT_ARC}" -o /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt


# Install aws-cli
RUN curl -s "https://awscli.amazonaws.com/awscli-exe-linux-${AWSCLI_ARC}.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
    
# Setup Git username and email
RUN eval echo '[user]\\n\
        email = "${GIT_USERMAIL}"\\n\
        name = "${GIT_USERNAME}"' >> /home/vscode/.gitconfig

# Setup .terraformrc
RUN mkdir -p /home/vscode/.terrraform.d/pluging-cache
RUN echo 'plugin_cache_dir   = "/home/vscode/.terrraform.d/pluging-cache"' > /home/vscode/.terraformrc

VOLUME [ "/var/lib/docker" ]

# Setting the ENTRYPOINT to docker-init.sh will start up the Docker Engine 
# inside the container "overrideCommand": false is set in devcontainer.json. 
# The script will also execute CMD if you need to alter startup behaviors.
# ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>