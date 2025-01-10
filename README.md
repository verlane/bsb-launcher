# BSBLauncher

BSBLauncher is a powerful, lightweight launcher program built with **AutoHotkey (AHK)**.  
It allows users to quickly execute scripts, applications, or commands via a versatile input box, designed as a modern replacement for **Find and Run Robot 2 (FARR2)**.

---

## Features

- **Dynamic Command Execution**  
  Easily execute `.ahk` scripts stored in the `./commands/` folder. For example:
  - Writing a script `./commands/g.ahk` allows you to run it by typing `g args` in the launcher.  
  - This will execute it as `g.ahk args`, passing any arguments directly to the script.

- **Customizable Launcher**  
  Add frequently used applications, files, and scripts to the launcher for easy access.

- **Execution History**  
  Keeps track of recent commands and files for quick relaunching.

- **Find and Run Robot 2 Replacement**  
  Built specifically to provide a clean, modern alternative to FARR2.

- **Lightweight and Fast**  
  Optimized for performance with minimal resource usage.

---

## Installation

1. **Download AutoHotkey**  
   Ensure [AutoHotkey](https://www.autohotkey.com/) is installed on your system.

2. **Clone or Download**  
   - Clone this repository:
     ```bash
     git clone https://github.com/yourusername/BSBLauncher.git
     ```
   - Or download the ZIP file and extract it to your preferred location.

3. **Create Your Commands**  
   - Add your custom `.ahk` files to the `./commands/` folder.
   - For example:
     - Create `./commands/g.ahk` with the following content:
       ```autohotkey
       MsgBox, You passed these arguments: %*
       ```
     - Running `g args` in the launcher will execute `g.ahk args`.

4. **Run the Launcher**  
   - Double-click `BSBLauncher.ahk` to start the program.
   - Ctrl + ; and enter keyword
   
---

## Usage

1. **Launching Scripts and Commands**  
   - Open the launcher input box by invoking the hotkey (customizable).  
   - Type the command corresponding to the `.ahk` file name in the `./commands/` folder.  
   - For example:  
     - Command: `g args`  
     - Action: Runs `g.ahk` with `args` as its argument.  

2. **Adding Custom Applications or Files**  
   - Use the built-in settings or edit the script to add frequently used applications, files, or scripts.

3. **Execution History**  
   - Quickly relaunch recently used commands from the history list.

---

## Example Configuration

### Adding Custom `.ahk` Commands

1. Create a script in the `./commands/` folder, e.g., `./commands/openurl.ahk`:
   ```autohotkey
   Run, https://www.example.com
   Run the command in the launcher input box:
   openurl
   ```
   
2. Adding External Applications
   ```autohotkey
   newItem := ClassExeFile("C:\Program Files\Notepad++\notepad++.exe", "Notepad++")
   Launcher.AddItem(newItem)
   ```

## Why BSBLauncher?

This program is designed to replace Find and Run Robot 2 (FARR2) with a more modern, customizable, and lightweight alternative.
Its ability to dynamically execute .ahk scripts with arguments from the ./commands/ folder makes it highly flexible and easy to extend.
