# 🐥 NightlyShutdown 🐥

*A PowerShell utility to auto-shutdown your PC if left unattended.*

For anyone who falls asleep (or steps away) with their PC still running—whether you're binge-watching or just forget to shut down. It gently prompts you, then gracefully closes apps and powers off if there's no response.

## How it works

1. Displays a full-screen neon-style prompt (“Are you still there?”) with a 2-minute timeout.  
2. If unanswered, shows toast notifications (via BurntToast) and, in order:
   - Minimizes all windows  
   - Mutes system audio  
   - Attempts to close all user-visible applications (twice for safety)  
   - Shuts down the computer  

Each step gives you time to intervene before the next action.

## Requirements

- Windows 8.1, 10, or 11  
- PowerShell 4.0–5.1  
- [BurntToast module](https://www.powershellgallery.com/packages/BurntToast)  

## Installation

1. Just install BurntToast (one‑time, probably already installed):
   ```powershell
   Install-Module BurntToast -Force -Scope CurrentUser
   ```
   or
      ```powershell
   Install-Module -Name BurntToast -RequiredVersion 0.8.5
   ```
   
## Scheduling (via Task Scheduler)

1. Open Task Scheduler.
2. Create a new **Basic Task**.
3. Set a **Trigger**: choose when it should run (e.g. daily at 1 AM).
4. Set **Action**:
   - **Program/script**: `powershell.exe`
   - **Add arguments**: 
     ```plaintext
     -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\sleep.ps1"
     ```
5. Finish and confirm.


## License

This project is released under [The Unlicense](https://unlicense.org/). Do whatever you want.

