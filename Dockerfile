FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    gnupg \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Add Freelens Apt repository and install Freelens
RUN curl -L https://raw.githubusercontent.com/freelensapp/freelens/refs/heads/main/freelens/build/apt/freelens.asc | tee /etc/apt/keyrings/freelens.asc && \
    curl -L https://raw.githubusercontent.com/freelensapp/freelens/refs/heads/main/freelens/build/apt/freelens.sources | tee /etc/apt/sources.list.d/freelens.sources && \
    apt update && apt -y install freelens && \
    rm -rf /var/lib/apt/lists/*

# Create custom services directory for LinuxServer init system
RUN mkdir -p /etc/services.d/freelens

# Create the run script for Freelens auto-start
RUN cat > /etc/services.d/freelens/run << 'EOF'
#!/usr/bin/with-contenv bash

# Wait for desktop to be ready
sleep 10

# Set display
export DISPLAY=:1

# Run as the abc user
exec s6-setuidgid abc /usr/bin/freelens --no-sandbox --ozone-platform-hint=auto --enable-features=WebRTCPipeWireCapturer --enable-features=WaylandWindowDecorations --disable-gpu-compositing
EOF

RUN chmod +x /etc/services.d/freelens/run

# Create desktop shortcut
RUN mkdir -p /config/Desktop && \
    cat > /config/Desktop/freelens.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Lens Desktop
Comment=Freelens IDE
Exec=/usr/bin/freelens --no-sandbox --ozone-platform-hint=auto --enable-features=WebRTCPipeWireCapturer --enable-features=WaylandWindowDecorations --disable-gpu-compositing
Icon=lens
Terminal=false
Categories=Development;
EOF

RUN chmod +x /config/Desktop/freelens.desktop

# Copy custom icon for web-freelens
COPY --chown=abc:abc web-freelens.png /usr/share/selkies/www/icon.png

# Set permissions for config file
RUN chown -R abc:abc /config