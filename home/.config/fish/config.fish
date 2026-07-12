# update path
fish_add_path -g "$HOME/.local/bin"
fish_add_path -g "$HOME/.cargo/bin"

# pyenv
set -gx PYENV_ROOT "$HOME/.pyenv"
fish_add_path -g "$PYENV_ROOT/bin"
pyenv init - fish | source

# pyenv build options
set -gx PYTHON_CONFIGURE_OPTS '--enable-optimizations --with-lto'
set -gx PYTHON_CFLAGS '-march=native -mtune=native'
set -gx MAKE_OPTS "-j$(nproc)"

if status is-interactive
    # Commands to run in interactive sessions can go here
    macchina
    fish_config theme choose "Solarized Light"
    set fish_greeting
    set -gx EDITOR "$HOME/.local/bin/nvim"
end
