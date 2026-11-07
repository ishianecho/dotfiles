#!/usr/bin/env bash

set -euo pipefail

lombok_version="1.18.48"
kotlin_lsp_version="263.7084.0"
groovy_ls_ref="347d098a928707223ce44b52cc45174a6327a5f3"
jdtls_version="1.63.0"
jdtls_build="202610191322"

specs=(
  "clangd	github:clangd/clangd@23.1.0"
  "vscode-css-language-server	npm:vscode-langservers-extracted@4.10.0"
  "vscode-html-language-server	npm:vscode-langservers-extracted@4.10.0"
  "vscode-json-language-server	npm:vscode-langservers-extracted@4.10.0"
  "docker-langserver	npm:dockerfile-language-server-nodejs@0.15.0"
  "docker-compose-langserver	github:microsoft/compose-language-service@microsoft-compose-language-service-v0.5.0"
  "gh-actions-language-server	npm:gh-actions-language-server@0.0.3"
  "helm_ls	helm-ls@0.5.4"
  "marksman	marksman@2026-02-08"
  "nginx-language-server	pipx:nginx-language-server@0.9.0"
  "rust-analyzer	rust-analyzer@2026-11-02"
  "taplo	taplo@0.10.0"
  "texlab	cargo:texlab@4.3.2"
  "tinymist	tinymist@0.15.12"
  "ts_query_ls	github:ribru17/ts_query_ls@3.16.0"
  "bash-language-server	npm:bash-language-server@5.8.1"
  "gopls	go:golang.org/x/tools/gopls@0.24.0"
  "jdtls	jdtls"
  "typescript-language-server	npm:typescript-language-server@6.0.3"
  "tsc	npm:typescript@6.0.3"
  "lua-language-server	lua-language-server@3.19.2"
  "buf	buf@1.75.0"
  "ty	ty@0.0.97"
  "sqls	go:github.com/sqls-server/sqls@0.2.48"
  "typos-lsp	cargo:typos-lsp@0.1.57"
  "vtsls	npm:@vtsls/language-server@0.3.0"
  "vue-language-server	npm:@vue/language-server@3.3.14"
  "lemminx	github:redhat-developer/vscode-xml@0.29.3"
  "yaml-language-server	npm:yaml-language-server@2.0.0"
  "cpplint	pipx:cpplint@2.0.2"
  "stylelint	npm:stylelint@18.0.0"
  "hadolint	hadolint@2.15.1"
  "golangci-lint	golangci-lint@2.15.0"
  "htmlhint	npm:htmlhint@1.9.2"
  "eslint_d	npm:eslint_d@15.1.0"
  "jsonlint	npm:jsonlint@1.6.3"
  "ruff	ruff@0.17.3"
  "prettier	npm:prettier@3.9.10"
  "goimports	go:golang.org/x/tools/cmd/goimports@0.52.0"
  "gofumpt	go:mvdan.cc/gofumpt@0.12.0"
  "google-java-format	google-java-format@2.0.0"
  "stylua	stylua@2.6.0"
  "typstyle	typstyle@0.15.2"
  "nginxfmt	pipx:nginxfmt@1.4.0"
  "intellij-server	kotlin-lsp"
  "groovy-language-server	groovy-lsp"
)

install_lombok() {
  local jdtls_dir
  jdtls_dir="$(ls -d "$HOME"/.local/share/jdtls/jdt-language-server-* 2>/dev/null | sort -V | tail -1 || true)"
  if [ -z "$jdtls_dir" ]; then
    return 0
  fi
  if [ -f "$jdtls_dir/lombok.jar" ]; then
    return 0
  fi
  echo "Installing lombok $lombok_version into $jdtls_dir ..."
  curl -fL -o "$jdtls_dir/lombok.jar.tmp.$$" \
    "https://repo1.maven.org/maven2/org/projectlombok/lombok/$lombok_version/lombok-$lombok_version.jar" \
    && mv "$jdtls_dir/lombok.jar.tmp.$$" "$jdtls_dir/lombok.jar"
}

link_ts_ls_typescript() {
  local ts_dir
  ts_dir="$(ls -d "$HOME"/.local/share/mise/installs/npm-typescript/*/node_modules/typescript 2>/dev/null | sort -V | tail -1 || true)"
  if [ -z "$ts_dir" ] || [ ! -f "$ts_dir/lib/tsserver.js" ]; then
    return 0
  fi
  local dir
  for dir in "$HOME"/.local/share/mise/installs/npm-typescript-language-server/*; do
    [ -d "$dir/node_modules" ] || continue
    if [ "$(readlink "$dir/node_modules/typescript" 2>/dev/null)" != "$ts_dir" ]; then
      ln -sfn "$ts_dir" "$dir/node_modules/typescript"
    fi
  done
}

install_jdtls() {
  local dest="$HOME/.local/share/jdtls"
  local dir="$dest/jdt-language-server-$jdtls_version"
  if [ -x "$dir/bin/jdtls" ] && ls "$dir/plugins"/org.eclipse.equinox.launcher_*.jar >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$dir/bin/jdtls" "$HOME/.local/bin/jdtls"
    return 0
  fi
  echo "Installing jdtls $jdtls_version ..."
  rm -rf "$dir"
  mkdir -p "$dest"
  local tmp
  tmp=$(mktemp -d "$dest/.tmp-jdtls-XXXXXX")
  if ! { curl -fL "https://download.eclipse.org/jdtls/milestones/$jdtls_version/jdt-language-server-$jdtls_version-$jdtls_build.tar.gz" \
      | tar -xz -C "$tmp" \
      && ls "$tmp/plugins"/org.eclipse.equinox.launcher_*.jar >/dev/null 2>&1 \
      && mv "$tmp" "$dir"; }; then
    rm -rf "$tmp"
    echo "jdtls install failed" >&2
    return 1
  fi
  mkdir -p "$HOME/.local/bin"
  ln -sf "$dir/bin/jdtls" "$HOME/.local/bin/jdtls"
  install_lombok
  echo "jdtls installed: ~/.local/bin/jdtls"
}

install_kotlin_lsp() {
  if command -v intellij-server >/dev/null 2>&1; then
    return 0
  fi
  echo "Installing Kotlin LSP $kotlin_lsp_version ..."
  local dest="$HOME/.local/share/kotlin-lsp"
  if [ ! -x "$dest/kotlin-server-$kotlin_lsp_version/bin/intellij-server" ]; then
    mkdir -p "$dest"
    curl -fL "https://download.jetbrains.com/language-server/kotlin-server/$kotlin_lsp_version/kotlin-server-$kotlin_lsp_version.tar.gz" \
      | tar -xz -C "$dest"
  fi
  mkdir -p "$HOME/.local/bin"
  ln -sf "$dest/kotlin-server-$kotlin_lsp_version/bin/intellij-server" "$HOME/.local/bin/intellij-server"
  echo "Kotlin LSP installed: ~/.local/bin/intellij-server"
}

install_groovyls() {
  if command -v groovy-language-server >/dev/null 2>&1; then
    return 0
  fi
  local java_bin
  java_bin="$(command -v java || true)"
  if [ -z "$java_bin" ] && [ -x "$HOME/.local/share/mise/shims/java" ]; then
    java_bin="$HOME/.local/share/mise/shims/java"
  fi
  if [ -z "$java_bin" ]; then
    echo "no java found, cannot build Groovy language server" >&2
    return 1
  fi
  local dest="$HOME/.local/share/groovy-language-server"
  if [ ! -d "$dest/.git" ]; then
    git clone https://github.com/prominic/groovy-language-server.git "$dest"
  fi
  git -C "$dest" checkout -q "$groovy_ls_ref"
  local jar="$dest/build/libs/groovy-language-server-all.jar"
  if [ ! -f "$jar" ]; then
    echo "Building Groovy language server ..."
    (cd "$dest" && ./gradlew --no-daemon build) || {
      echo "Failed to build Groovy language server" >&2
      return 1
    }
  fi
  mkdir -p "$HOME/.local/bin"
  printf '#!/usr/bin/env bash\nexec "%s" -jar "%s" "$@"\n' "$java_bin" "$jar" > "$HOME/.local/bin/groovy-language-server"
  chmod +x "$HOME/.local/bin/groovy-language-server"
  echo "Groovy language server installed: ~/.local/bin/groovy-language-server"
}

install_selected() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local mise_batch=()
  local bg_specs=() bg_pids=() bg_logs=()
  local spec i

  for spec in "$@"; do
    [ -n "$spec" ] || continue
    case "$spec" in
      jdtls)
        bg_specs+=("$spec")
        bg_logs+=("$tmpdir/${#bg_specs[@]}.log")
        install_jdtls >"${bg_logs[-1]}" 2>&1 </dev/null &
        bg_pids+=($!)
        ;;
      kotlin-lsp)
        bg_specs+=("$spec")
        bg_logs+=("$tmpdir/${#bg_specs[@]}.log")
        install_kotlin_lsp >"${bg_logs[-1]}" 2>&1 </dev/null &
        bg_pids+=($!)
        ;;
      groovy-lsp)
        bg_specs+=("$spec")
        bg_logs+=("$tmpdir/${#bg_specs[@]}.log")
        install_groovyls >"${bg_logs[-1]}" 2>&1 </dev/null &
        bg_pids+=($!)
        ;;
      *)
        mise_batch+=("$spec")
        ;;
    esac
  done

  local failed=0
  if [ ${#mise_batch[@]} -gt 0 ]; then
    echo "mise use -g ${mise_batch[*]}"
    mise use -g "${mise_batch[@]}" || failed=1
  fi

  for i in "${!bg_pids[@]}"; do
    if wait "${bg_pids[$i]}"; then
      echo "[ok] ${bg_specs[$i]}"
    else
      failed=1
      echo "[fail] ${bg_specs[$i]}"
      sed 's/^/    /' "${bg_logs[$i]}"
    fi
  done

  rm -rf "$tmpdir"
  return "$failed"
}

script_self="$HOME/src/chezmoi/.chezmoiscripts/posix/run_after_02-lsp-tools.sh"

if [ "$#" -gt 0 ]; then
  if install_selected "$@"; then
    exit 0
  fi
  exit 1
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "mise not installed, skipping LSP tools installer"
  exit 0
fi

missing_cmds=()
missing_specs=()
printed=""
for entry in "${specs[@]}"; do
  cmd="${entry%%	*}"
  spec="${entry#*	}"
  command -v "$cmd" >/dev/null 2>&1 && continue
  case " $printed " in *" $spec "*) continue ;; esac
  printed="$printed $spec"
  missing_cmds+=("$cmd")
  missing_specs+=("$spec")
done

install_lombok || true
link_ts_ls_typescript || true

count=${#missing_specs[@]}
if [ "$count" -eq 0 ]; then
  exit 0
fi

print_missing() {
  local spec
  echo "$count tool(s) missing, install with:"
  for spec in "${missing_specs[@]}"; do
    case "$spec" in
      jdtls | kotlin-lsp | groovy-lsp)
        echo "  bash $script_self $spec"
        ;;
      *)
        echo "  mise use -g $spec"
        ;;
    esac
  done
}

helpers_sh="$HOME/src/chezmoi/installers/lib/posix/helpers.sh"
if command -v chezmoi >/dev/null 2>&1; then
  chezmoi_src="$(chezmoi source-path 2>/dev/null || true)"
  if [ -n "$chezmoi_src" ] && [ -f "$chezmoi_src/installers/lib/posix/helpers.sh" ]; then
    helpers_sh="$chezmoi_src/installers/lib/posix/helpers.sh"
  fi
fi

if [ ! -t 0 ] || [ ! -t 1 ] || [ ! -f "$helpers_sh" ]; then
  print_missing
  exit 0
fi

. "$helpers_sh"

picker_options=()
for i in "${!missing_specs[@]}"; do
  picker_options+=("${missing_cmds[$i]}	${missing_specs[$i]}")
done

selected=""
if ! selected="$(multiselect "${picker_options[@]}")"; then
  selected=""
fi

if [ -z "$selected" ]; then
  print_missing
  exit 0
fi

chosen=()
while IFS= read -r line; do
  [ -n "$line" ] && chosen+=("${line#*	}")
done <<<"$selected"

if ! install_selected "${chosen[@]}"; then
  echo "some installs failed, re-run chezmoi apply to retry" >&2
  exit 1
fi

link_ts_ls_typescript || true
