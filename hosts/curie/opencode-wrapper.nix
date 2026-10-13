final: prev:
let
  original = prev.opencode;
  launcher = prev.writeShellApplication {
    name = "opencode";
    runtimeInputs = [
      prev.curl
      prev.jq
    ];
    text = ''
      endpoint=https://litellm.live.aix.cloud.otto.de
      auth_file="''${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"
      validate='if length == 1 and (.[0] | type) == "object" then .[0] else error("invalid auth object") end'

      if [[ -n "''${OPENCODE_AUTH_CONTENT:-}" ]]; then
        if ! auth_content=$(printf '%s' "$OPENCODE_AUTH_CONTENT" | jq -cs "$validate" 2>/dev/null); then
          printf '%s\n' 'opencode: invalid inline auth JSON.' >&2
          exit 1
        fi
      elif [[ -e "$auth_file" ]]; then
        if ! auth_content=$(jq -cs "$validate" "$auth_file" 2>/dev/null); then
          printf '%s\n' 'opencode: cannot read a valid auth JSON object.' >&2
          exit 1
        fi
      else
        exec ${original}/bin/opencode "$@"
      fi

      if jq -e --arg endpoint "$endpoint" 'has($endpoint)' <<< "$auth_content" >/dev/null; then
        if ! curl -q --silent --head --connect-timeout 1 --max-time 1 --output /dev/null "$endpoint"; then
          OPENCODE_AUTH_CONTENT=$(jq -c --arg endpoint "$endpoint" 'del(.[$endpoint])' <<< "$auth_content")
          export OPENCODE_AUTH_CONTENT
        fi
      fi

      exec ${original}/bin/opencode "$@"
    '';
  };
in
{
  opencode = prev.symlinkJoin {
    name = "opencode-vpn-${original.version}";
    inherit (original) version meta;
    paths = [ original ];
    postBuild = ''
      rm "$out/bin/opencode"
      ln -s ${launcher}/bin/opencode "$out/bin/opencode"
    '';
  };
}
