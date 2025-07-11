# Multi-platform ejabberd Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg2 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add Erlang repository
RUN wget -O- https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb | dpkg -i - && \
    apt-get update && apt-get install -y esl-erlang && rm -rf /var/lib/apt/lists/*

# Install ejabberd
RUN apt-get update && apt-get install -y ejabberd && rm -rf /var/lib/apt/lists/*

# Create ejabberd user
RUN useradd -m -d /home/ejabberd ejabberd

# Set up ejabberd configuration
RUN mkdir -p /home/ejabberd/conf && \
    mkdir -p /home/ejabberd/database && \
    mkdir -p /home/ejabberd/logs && \
    chown -R ejabberd:ejabberd /home/ejabberd

# Copy basic configuration
COPY <<EOF /home/ejabberd/conf/ejabberd.yml
hosts:
  - "ejabberd.local"

loglevel: info

listen:
  -
    port: 5222
    module: ejabberd_c2s
    max_stanza_size: 262144
    shaper: c2s_shaper
    access: c2s
    starttls_required: true
  -
    port: 5269
    module: ejabberd_s2s_in
    max_stanza_size: 524288
  -
    port: 5280
    module: ejabberd_http
    request_handlers:
      "/admin": ejabberd_web_admin
      "/api": mod_http_api
      "/": ejabberd_http

modules:
  mod_adhoc: {}
  mod_admin_extra: {}
  mod_announce:
    access: announce
  mod_http_api:
    api_key: "your-api-key"
  mod_http_upload: {}
  mod_mam:
    assume_mam_usage: true
    default: always
  mod_mqtt: {}
  mod_muc:
    access:
      - allow
    access_admin:
      - allow: admin
    access_create: muc_create
    access_persistent: muc_create
    access_mam:
      - allow
    default_room_jid: ""
    default_room_options:
      mam: true
      persistent: true
  mod_muc_light: {}
  mod_offline:
    access_max_user_messages: max_user_offline_messages
  mod_ping: {}
  mod_pres_counter:
    count_offline: true
  mod_push: {}
  mod_push_keepalive: {}
  mod_roster:
    versioning: true
  mod_s2s_dialback: {}
  mod_stream_mgmt:
    max_fsm_queue: 1000
  mod_vcard: {}
  mod_vcard_xupdate: {}
  mod_version:
    show_os: false

auth_method: internal

access_rules:
  local:
    - allow: local
  c2s:
    - deny: blocked
    - allow
  c2s_shaper:
    - allow
  s2s_shaper:
    - allow
  announce:
    - allow: admin
  configure:
    - allow: admin
  muc_create:
    - allow: local
  pubsub_createnode:
    - allow: local
  trusted_network:
    - allow

shaper_rules:
  max_user_sessions: 10
  max_user_offline_messages:
    - 5000: admin
    - 100
  c2s_shaper:
    - none: admin
    - normal
  s2s_shaper: fast

api_permissions:
  "console commands":
    - from: ejabberd_ctl
      commands: "*"
  "admin access":
    - from: ejabberd_web_admin
      oauth:
        scope: "ejabberd:admin"
        admin: true
EOF

# Set permissions
RUN chown -R ejabberd:ejabberd /home/ejabberd/conf

# Expose ports
EXPOSE 5222 5269 5280

# Switch to ejabberd user
USER ejabberd

# Set working directory
WORKDIR /home/ejabberd

# Start ejabberd
CMD ["ejabberdctl", "foreground"] 