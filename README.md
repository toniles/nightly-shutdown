# NightlyShutdown

A simple PowerShell utility for anyone who falls asleep (or steps away) with their PC still running—whether you’re binge‑watching or simply forget to shut down. It gently prompts you, then gracefully closes apps and powers off if there’s no response.

## How it works

1. Displays a full‑screen neon‑style prompt (“Are you still there?”) with a 2‑minute timeout.  
2. If unanswered, shows toast notifications (via BurntToast) and in order:  
   - Minimizes all windows  
   - Mutes system audio  
   - Attempts to close all user‑visible applications (twice for safety)  
   - Shuts down the computer  

Each step gives you time to intervene before the next action.

## Requirements

- WINDOWS 8.1, 10, 11
- PowerShell 4, 5, 5.1 
- [BurntToast module](https://www.powershellgallery.com/packages/BurntToast) 

## Installation

1. Just install BurntToast (one‑time, probably already installed):
   ```powershell
   Install-Module BurntToast -Force -Scope CurrentUser
   ```
## Scheduling

Use Windows Task Scheduler to run it automatically at your chosen times (e.g. nightly or hourly):

1. Open **Task Scheduler**
2. Create a new Basic Task:
   - **Action**: Start a program  
   - **Program/script**: `powershell.exe`  
   - **Add arguments**: `-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\sleep.ps1"`  
3. Set trigger(s) to the hour(s) you want it to run.

That’s it—your PC will politely check for you, then shut down safely if you’ve already dozed off.

## License

Unlicensed – do whatever you want.
