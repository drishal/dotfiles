{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;

  tmuxAgentStatus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-agent-status";
    version = "unstable-2026-06-24";
    src = inputs.tmux-agent-status;
    rtpFilePath = "tmux-agent-status.tmux";
    postPatch = ''
            substituteInPlace tmux-agent-status.tmux \
              --replace-fail 'tmux set-option -g status-interval 1' \
                             '# status-interval is managed by Home Manager' \
              --replace-fail '"$CURRENT_DIR/scripts/sidebar-collector.sh" &' \
                             '"$CURRENT_DIR/scripts/sidebar-collector.sh" >/dev/null 2>&1 &'
            sed -i '/# Auto-create sidebar in new sessions/,/tmux set-hook -ga session-created/d' \
              tmux-agent-status.tmux
            sed -i '/    # Create sidebar in all existing sessions/,/    done/d' \
              tmux-agent-status.tmux
            sed -i '0,/tmux set-hook -ga session-created/s//tmux set-hook -g "session-created[800]"/' \
              tmux-agent-status.tmux
            sed -i '0,/tmux set-hook -ga session-created/s//tmux set-hook -g "session-created[808]"/' \
              tmux-agent-status.tmux
            sed -i \
              -e 's/tmux set-hook -ga client-attached/tmux set-hook -g "client-attached[801]"/' \
              -e 's/tmux set-hook -ga client-session-changed/tmux set-hook -g "client-session-changed[802]"/' \
              -e 's/tmux set-hook -ga after-select-pane/tmux set-hook -g "after-select-pane[803]"/' \
              -e 's/tmux set-hook -ga after-select-window/tmux set-hook -g "after-select-window[804]"/' \
              -e 's/tmux set-hook -ga after-switch-client/tmux set-hook -g "client-active[805]"/' \
              -e 's/tmux set-hook -ga session-window-changed/tmux set-hook -g "session-window-changed[806]"/' \
              -e 's/tmux set-hook -ga window-pane-changed/tmux set-hook -g "window-pane-changed[807]"/' \
              -e 's/tmux set-hook -ga pane-exited/tmux set-hook -g "pane-exited[809]"/' \
              -e 's/tmux set-hook -ga window-layout-changed/tmux set-hook -g "window-layout-changed[810]"/' \
              -e 's/tmux set-hook -ga after-new-window/tmux set-hook -g "after-new-window[811]"/' \
              -e 's/tmux set-hook -ga after-kill-window/tmux set-hook -g "window-unlinked[812]"/' \
              -e 's/tmux set-hook -ga after-rename-window/tmux set-hook -g "after-rename-window[813]"/' \
              tmux-agent-status.tmux
            substituteInPlace scripts/lib/collect.sh \
              --replace-fail 'pgrep -a "claude|codex|devin"' \
                             'pgrep -a "claude|codex|devin|hermes|opencode"' \
              --replace-fail '[[ "$acmd" == *devin* ]] && agent_name="devin"' \
                             '[[ "$acmd" == *devin* ]] && agent_name="devin"
                  [[ "$acmd" == *hermes* ]] && agent_name="hermes"
                  [[ "$acmd" == *opencode* ]] && agent_name="opencode"'
            substituteInPlace scripts/daemon-monitor.sh \
              --replace-fail 'SMART_MONITOR="$SCRIPT_DIR/../smart-monitor.sh"' \
                             'SMART_MONITOR="$SCRIPT_DIR/../smart-monitor.sh"

      mkdir -p "$STATUS_DIR"
      exec 9>"$STATUS_DIR/daemon-monitor.lock"
      ${lib.getExe' pkgs.util-linux "flock"} -n 9 || exit 0' \
              --replace-fail '    echo $$ > "$MONITOR_PID_FILE"' \
                             "" \
              --replace-fail ') &' \
                             ') &
      echo "$!" > "$MONITOR_PID_FILE"'
    '';
  };

  agentStatusRoot = "${tmuxAgentStatus}/share/tmux-plugins/tmux-agent-status";
  extraktoRoot = "${pkgs.tmuxPlugins.extrakto}/share/tmux-plugins/extrakto";

  tmuxAgentState = pkgs.writeShellApplication {
    name = "tmux-agent-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.tmux
    ];
    text = builtins.readFile ./tmux/agent-state.sh;
  };

  hermesAgentStatus = pkgs.replaceVars ./tmux/hermes-agent-status.py {
    tmuxAgentState = lib.getExe tmuxAgentState;
  };

  opencodeAgentStatus = pkgs.replaceVars ./tmux/opencode-agent-status.js {
    tmuxAgentState = lib.getExe tmuxAgentState;
  };
in
{
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    baseIndex = 1;
    clock24 = true;
    escapeTime = 10;
    focusEvents = true;
    historyLimit = 100000;
    aggressiveResize = true;
    customPaneNavigationAndResize = true;
    resizeAmount = 3;

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = extrakto;
        extraConfig = ''
          set -g @extrakto_key "Tab"
          set -g @extrakto_grab_area "window 5000"
          set -g @extrakto_filter_order "path url quote word line"
          set -g @extrakto_clip_tool_run "tmux_osc52"
        '';
      }
      {
        plugin = tmuxAgentStatus;
        extraConfig = ''
          set -g @agent-switcher-style "popup"
          set -g @agent-switcher-default-mode "agents"
          set -g @agent-status-key "S"
          set -g @agent-next-done-key "N"
          set -g @agent-wait-key "W"
          set -g @agent-park-key "P"
          set -g @agent-notification-sound "none"
          set -g @agent-ask-sound "none"
        '';
      }
    ];

    tmux-which-key = {
      enable = true;
      settings = {
        command_alias_start_index = 200;
        custom_variables = [ ];
        keybindings.prefix_table = "Space";
        macros = [ ];
        title = {
          style = "align=centre,bold";
          prefix = "tmux";
          prefix_style = "fg=${c.base0D},align=centre,bold";
        };
        position = {
          x = "C";
          y = "P";
        };
        items = [
          {
            name = "+Windows";
            key = "w";
            menu = [
              {
                name = "Choose";
                key = "w";
                command = "choose-tree -Zw";
              }
              {
                name = "Last";
                key = "Tab";
                command = "last-window";
              }
              {
                name = "Previous";
                key = "p";
                command = "previous-window";
                transient = true;
              }
              {
                name = "Next";
                key = "n";
                command = "next-window";
                transient = true;
              }
              {
                name = "New";
                key = "c";
                command = "new-window -c \"#{pane_current_path}\"";
              }
              {
                name = "Rename";
                key = "r";
                command = "command-prompt -p \"Rename window:\" -I \"#W\" \"rename-window -- \\\"%%\\\"\"";
              }
              {
                name = "Kill";
                key = "x";
                command = "confirm-before -p \"Kill window #W?\" kill-window";
              }
            ];
          }
          {
            name = "+Panes";
            key = "p";
            menu = [
              {
                name = "Choose";
                key = "p";
                command = "display-panes -d 0";
              }
              {
                name = "Left";
                key = "h";
                command = "select-pane -L";
                transient = true;
              }
              {
                name = "Down";
                key = "j";
                command = "select-pane -D";
                transient = true;
              }
              {
                name = "Up";
                key = "k";
                command = "select-pane -U";
                transient = true;
              }
              {
                name = "Right";
                key = "l";
                command = "select-pane -R";
                transient = true;
              }
              { separator = true; }
              {
                name = "Split right";
                key = "v";
                command = "split-window -h -c \"#{pane_current_path}\"";
              }
              {
                name = "Split down";
                key = "s";
                command = "split-window -v -c \"#{pane_current_path}\"";
              }
              {
                name = "Zoom";
                key = "z";
                command = "resize-pane -Z";
              }
              {
                name = "+Resize";
                key = "r";
                menu = [
                  {
                    name = "Left";
                    key = "h";
                    command = "resize-pane -L 3";
                    transient = true;
                  }
                  {
                    name = "Down";
                    key = "j";
                    command = "resize-pane -D 3";
                    transient = true;
                  }
                  {
                    name = "Up";
                    key = "k";
                    command = "resize-pane -U 3";
                    transient = true;
                  }
                  {
                    name = "Right";
                    key = "l";
                    command = "resize-pane -R 3";
                    transient = true;
                  }
                ];
              }
              {
                name = "Kill";
                key = "x";
                command = "confirm-before -p \"Kill pane #P?\" kill-pane";
              }
            ];
          }
          {
            name = "+Sessions";
            key = "s";
            menu = [
              {
                name = "Choose";
                key = "s";
                command = "choose-tree -Zs";
              }
              {
                name = "New";
                key = "n";
                command = "command-prompt -p \"Session name:\" \"new-session -A -s \\\"%%\\\" -c \\\"#{pane_current_path}\\\"\"";
              }
              {
                name = "Rename";
                key = "r";
                command = "command-prompt -p \"Rename session:\" -I \"#S\" \"rename-session -- \\\"%%\\\"\"";
              }
              {
                name = "Detach";
                key = "d";
                command = "detach-client";
              }
            ];
          }
          {
            name = "+AI agents";
            key = "a";
            menu = [
              {
                name = "Attention queue";
                key = "a";
                command = "run-shell -b \"TMUX_AGENT_SWITCHER_MODE=agents '${agentStatusRoot}/scripts/switcher-popup-loop.sh'\"";
              }
              {
                name = "Next ready";
                key = "n";
                command = "run-shell -b \"'${agentStatusRoot}/scripts/next-done-project.sh'\"";
              }
              {
                name = "Wait";
                key = "w";
                command = "run-shell -b \"'${agentStatusRoot}/scripts/wait-session.sh'\"";
              }
              {
                name = "Park";
                key = "p";
                command = "run-shell -b \"'${agentStatusRoot}/scripts/park-session.sh'\"";
              }
              { separator = true; }
              {
                name = "Claude";
                key = "c";
                command = "new-window -n claude -c \"#{pane_current_path}\" \"claude\"";
              }
              {
                name = "Claude resume";
                key = "C";
                command = "new-window -n claude -c \"#{pane_current_path}\" \"claude --continue\"";
              }
              {
                name = "Claude worktree";
                key = "t";
                command = "command-prompt -p \"Worktree name:\" \"new-window -n \\\"claude:%%\\\" -c \\\"#{pane_current_path}\\\" \\\"claude --worktree %%\\\"\"";
              }
              {
                name = "Codex";
                key = "x";
                command = "new-window -n codex -c \"#{pane_current_path}\" \"codex\"";
              }
              {
                name = "Codex resume";
                key = "X";
                command = "new-window -n codex -c \"#{pane_current_path}\" \"codex resume --last\"";
              }
              {
                name = "OpenCode";
                key = "o";
                command = "new-window -n opencode -c \"#{pane_current_path}\" \"opencode\"";
              }
              {
                name = "Hermes";
                key = "h";
                command = "new-window -n hermes -c \"#{pane_current_path}\" \"hermes\"";
              }
              {
                name = "Herdr workspace";
                key = "H";
                command = "new-window -n herdr -c \"#{pane_current_path}\" \"herdr\"";
              }
            ];
          }
          { separator = true; }
          {
            name = "Extract text";
            key = "e";
            command = "run-shell \"'${extraktoRoot}/scripts/open.sh' '#{pane_id}'\"";
          }
          {
            name = "Copy mode";
            key = "c";
            command = "copy-mode";
          }
          {
            name = "Reload config";
            key = "r";
            command = "source-file ~/.config/tmux/tmux.conf";
          }
          {
            name = "List keys";
            key = "?";
            command = "list-keys -N";
          }
        ];
      };
    };

    extraConfig = ''
      set -gq allow-passthrough on

      # true color passthrough (keeps stylix palette accurate in TUIs)
      set -ag terminal-features ",*:RGB"

      # panes from 1 (windows via baseIndex), keep them gapless after closing
      setw -g pane-base-index 1
      set -g renumber-windows on

      # new splits/windows inherit the current pane's path
      bind '"' split-window -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Clipboard: copy to system clipboard via OSC52
      set -g set-clipboard external
      set -ag terminal-features ",*:clipboard:osc52"
      set -ag terminal-overrides ",xterm-256color:clipboard:osc52"
      set -ag terminal-overrides ",tmux-256color:clipboard:osc52"

      # vi copy mode: v/C-v select, Enter/y and mouse drag copy to clipboard
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel

      # session and pane ergonomics
      set -g detach-on-destroy on
      set -g display-time 4000
      set -g status-interval 5
      set -g pane-scrollbars modal
      set -g pane-scrollbars-position right
      setw -g monitor-activity on
      set -g visual-activity off
      set -g activity-action other
      bind R source-file ~/.config/tmux/tmux.conf \; display-message "tmux config reloaded"

      # keep tmux navigation behind the prefix
      unbind-key -q -T root C-h
      unbind-key -q -T root C-j
      unbind-key -q -T root C-k
      unbind-key -q -T root C-l
      unbind-key -q -T root C-\\

      # === Theme (stylix) ===
      set -g status-style "bg=${c.base01},fg=${c.base05}"
      set -g status-left "#[fg=${c.base0D},bold] [#S] "
      set -g status-left-length 40
      set -g status-right "#(${agentStatusRoot}/scripts/status-line.sh) #[fg=${c.base04}] #{b:pane_current_path} · %H:%M #[bg=${c.base0D},fg=${c.base00},bold] #h "
      set -g status-right-length 120

      set -g window-status-format "#[fg=${c.base04}] #{?window_activity_flag,!,}#I #W#{?window_zoomed_flag, Z,} "
      set -g window-status-current-format "#[bg=${c.base0D},fg=${c.base00},bold] #I #[bg=${c.base02},fg=${c.base05}] #W#{?window_zoomed_flag, Z,} "
      set -g window-status-separator ""

      set -g pane-border-style "fg=${c.base02}"
      set -g pane-active-border-style "fg=${c.base0D}"
      set -g pane-scrollbars-style "fg=${c.base0D},bg=${c.base02}"
      set -g display-panes-colour "${c.base04}"
      set -g display-panes-active-colour "${c.base0D}"
      set -g message-style "bg=${c.base02},fg=${c.base05}"
      set -g mode-style "bg=${c.base0D},fg=${c.base00}"
      set -g menu-style "bg=${c.base01},fg=${c.base05}"
      set -g menu-selected-style "bg=${c.base0D},fg=${c.base00},bold"
      set -g menu-border-style "fg=${c.base0D}"
    '';
  };

  home.file = {
    ".local/libexec/tmux-agent-status-hooks".source = "${agentStatusRoot}/hooks";
    ".hermes/plugins/tmux-agent-status/__init__.py".source = hermesAgentStatus;
    ".hermes/plugins/tmux-agent-status/plugin.yaml".source = ./tmux/hermes-plugin.yaml;
  };

  xdg.configFile."opencode/plugins/tmux-agent-status.js".source = opencodeAgentStatus;

  home.activation.mergeTmuxAgentHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    merge_agent_hooks() {
      kind="$1"
      target="$2"
      mkdir -p "$(dirname "$target")"
      [ -f "$target" ] || printf '{"hooks":{}}\n' > "$target"

      tmp="$(${pkgs.coreutils}/bin/mktemp "$target.tmp.XXXXXX")"
      if ! ${pkgs.jq}/bin/jq \
        --arg kind "$kind" \
        --arg session_start "bash ~/.local/libexec/tmux-agent-status-hooks/codex-hook.sh SessionStart" \
        --arg prompt "bash ~/.local/libexec/tmux-agent-status-hooks/$([ "$kind" = claude ] && printf better || printf codex)-hook.sh UserPromptSubmit" \
        --arg pre_tool "bash ~/.local/libexec/tmux-agent-status-hooks/$([ "$kind" = claude ] && printf better || printf codex)-hook.sh PreToolUse" \
        --arg stop "bash ~/.local/libexec/tmux-agent-status-hooks/$([ "$kind" = claude ] && printf better || printf codex)-hook.sh Stop" \
        --arg notification "bash ~/.local/libexec/tmux-agent-status-hooks/better-hook.sh Notification" \
        '
          def cleaned($event):
            [(.hooks[$event] // [])[]
              | .hooks = [(.hooks // [])[]
                  | select(((.command // "") | contains("tmux-agent-status-hooks/")) | not)]
              | select((.hooks | length) > 0)];
          def hook($command; $matcher):
            if $matcher == "" then
              { hooks: [{ type: "command", command: $command, timeout: 10 }] }
            else
              { matcher: $matcher, hooks: [{ type: "command", command: $command, timeout: 10 }] }
            end;
          .hooks = (.hooks // {})
          | .hooks.UserPromptSubmit = (cleaned("UserPromptSubmit") + [hook($prompt; "")])
          | .hooks.PreToolUse = (cleaned("PreToolUse") + [hook($pre_tool; if $kind == "codex" then "Bash" else "" end)])
          | .hooks.Stop = (cleaned("Stop") + [hook($stop; "")])
          | if $kind == "codex" then
              .hooks.SessionStart = (cleaned("SessionStart") + [hook($session_start; "startup|resume")])
            else
              .hooks.Notification = (cleaned("Notification") + [hook($notification; "")])
            end
        ' "$target" > "$tmp"; then
        rm -f "$tmp"
        return 1
      fi
      mv "$tmp" "$target"
    }

    merge_agent_hooks claude "$HOME/.claude/settings.json"
    merge_agent_hooks codex "$HOME/.codex/hooks.json"

    if [ -x "$HOME/.local/bin/hermes" ]; then
      "$HOME/.local/bin/hermes" plugins enable tmux-agent-status \
        --no-allow-tool-override >/dev/null
    fi
  '';
}
