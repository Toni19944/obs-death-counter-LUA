Python required (3.6+, 64-bit). OBS 28 and newer should support any Python version from 3.6 onwards. [Official OBS Wiki](https://github.com/obsproject/obs-studio/wiki/getting-started-with-obs-scripting).  
Tested on Python 3.10.
---

Simple counter plugin for OBS with hotkeys to add/remove/reset.  
I included separate solo and co-op files since I have them anyways. Even tho the co-op file can be used as solo just the same way.

---

## Installation/Setup

0. Make sure that python location is set in OBS (tools-scripts-Python Settings).
1. Download either the solo or co-op script and save it wherever you want.
2. Add the script in OBS (tools-scripts).
3. Create a Text (GDI+) source. Each player requires their own text source. 
4. Point the correct text files to each player in the scripts settings.  
>  - if you can't see the text file in the dropdown menu, press the refresh button (somewhere on the same toolbar where you pressed the + button to add the script).
5. Set hotkeys in obs settings - hotkeys.

   - Each player can have their own prefix/suffix so you can have player names set properly.
   - Each player (obviously) requires their own hotkeys.
  
