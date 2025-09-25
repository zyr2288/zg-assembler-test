# TRAINER MONSTER BATTLE SIMULATOR

## IMPORTANT

Steps to set the controller inputs in FCEUX:

Step 1: Open the emulator and click Config  
Step 2: Go to input  
Step 3: You will see port 1 and port 2 on the right. Make sure gamepad is selected in both ports, if not, select them below.  
Step 4: Click configure on the side and bind the keys for each virtual gamepad.  
For Port 1, Virtual Gamepad 1, Left = A, Right = D, SELECT = Left Shift, A = Up and B = any key you want for attacking.  
For Port 2, Virtual Gamepad 2, Left = left arrow, Right = right arrow, SELECT = right shift, A = up arrow and B = any key you want for attacking.  
Step 5: Close and you are done.  

## Building Game Executable

In VSCode terminal, go to down arrow besides the + sign and select Git Bash. There run these lines:  

sh build.sh build (Builds the NES file)
sh build.sh clean (Cleans the Obj files and NES file)