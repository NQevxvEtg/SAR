# Only run tmux if it's an interactive shell and not already inside a tmux session
if [ "$PS1" ] && [ -z "$TMUX" ]; then
    # Define the session name for each user, whether root or non-root
    SESSION_NAME="${USER}_session"
    
    # Attach to the user's tmux session if it exists, or create a new one
    tmux attach -t "$SESSION_NAME" || tmux new -s "$SESSION_NAME"
fi


#~/.tmux.conf
# set-hook -g client-attached "run-shell 'echo \"[tmux] Client attached: #{client_tty} at #{t:%Y-%m-%d %H:%M:%S}\" >> ~/tmux-attach.log'"
