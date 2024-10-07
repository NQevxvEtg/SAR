### Tmux Terminology

1. **Windows:**
   - In Tmux, a "window" is akin to a tab in a web browser. Each window can contain multiple panes.
   - You create a new window by pressing `Ctrl+b` followed by `c`.

2. **Panes:**
   - A "pane" is a subdivision within a window. You can split a window into multiple panes either horizontally or vertically.
   - You create a new pane by pressing `Ctrl+b` followed by `%` (for a vertical split) or `Ctrl+b` followed by `"` (for a horizontal split).

### Your Situation

When you used `Ctrl+b` followed by `%` or `"`, you were creating new panes within the existing windows, not new windows. This is why `tmux ls` still shows only 2 windows.

### Verifying Panes

To see the panes within a window, you can use the following commands while inside a Tmux session:

1. **List Panes in the Current Window:**
   ```bash
   Ctrl+b q
   ```
   This will briefly display the pane numbers in the current window.

2. **Navigate Between Panes:**
   - Use `Ctrl+b` followed by an arrow key (left, right, up, or down) to move between panes.
   - Alternatively, use `Ctrl+b` followed by `o` to cycle through the panes.

### Creating and Listing Windows

If you want to create more windows and have them listed by `tmux ls`, use the following commands:

1. **Create a New Window:**
   ```bash
   Ctrl+b c
   ```
   This will create a new window and switch to it.

2. **List All Windows in the Current Session:**
   ```bash
   Ctrl+b w
   ```
   This will display a list of all windows in the current Tmux session, allowing you to switch between them.

3. **Switch to a Specific Window:**
   ```bash
   Ctrl+b followed by the window number (e.g., 0, 1, 2, etc.)
   ```

### Example

To create 8 windows and verify them:

1. Press `Ctrl+b` followed by `c` to create a new window. Repeat this until you have 8 windows.
2. Use `Ctrl+b w` to list and switch between these windows.
3. Run `tmux ls` from a non-Tmux terminal to see all the windows listed.

By following these steps, you should see the correct number of windows when you run `tmux ls`.

Closing a window in Tmux can be done in several ways. Here are the most common methods:

### Method 1: Using the Tmux Command Prompt
1. **Open the Tmux Command Prompt:**
   Press `Ctrl+b` followed by `:`.
   
2. **Kill the Window:**
   Type the following command and press Enter:
   ```bash
   kill-window
   ```
   This will close the current window.

### Method 2: Using a Shortcut
1. **Kill the Current Window:**
   Press `Ctrl+b` followed by `&`.
   
2. **Confirm the Action:**
   Tmux will prompt you to confirm that you want to kill the window. Press `y` to confirm.

### Method 3: Exit the Shell
1. **Exit the Shell:**
   If you simply exit the shell running in the window (e.g., by typing `exit` or pressing `Ctrl+d`), Tmux will close the window automatically.
   ```bash
   exit
   ```
   or press `Ctrl+d`.

### Method 4: Kill a Specific Window by Number
1. **Open the Tmux Command Prompt:**
   Press `Ctrl+b` followed by `:`.
   
2. **Kill the Specific Window:**
   Type the following command and press Enter, replacing `window_number` with the number of the window you want to close:
   ```bash
   kill-window -t window_number
   ```

### Example
If you have a window numbered `2` that you want to close, you would:
1. Press `Ctrl+b :`
2. Type `kill-window -t 2` and press Enter.

### Additional Tips
- **List Windows:**
  If you are unsure of the window numbers, you can list all windows by pressing `Ctrl+b w`.
  
- **Switch to a Window:**
  To switch to a specific window before closing it, press `Ctrl+b` followed by the window number (e.g., `0`, `1`, `2`, etc.).

By using these methods, you can effectively close windows in Tmux and manage your terminal sessions more efficiently.
