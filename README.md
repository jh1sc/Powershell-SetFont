# Powershell-SetFont 🔢
- C# by u/Nation_State_Tractor

## Description 🪄
- This script is utilized to configure the font settings of a PowerShell console and command prompt environment. It offers a user-friendly interface and is effortless to implement. The module incorporates the Windows.Native.Kernel32 class which provides a comprehensive set of methods and constants for interacting with the Windows kernel via the kernel32.dll library. 

## How To Use It 🛠️
First of all in this module, there are 4 Functions.

- **SaveFont**: Self explanatory, it saves the font currently in use, for example if i was using consolas with a size of 14, I would use this function like, SaveFont {Save Name For Font}.

- **SetFont**: Again Self explanatory, just sets your font of choice from ListSavedFont, to use it do, SetFont {Save Name For Font}

- **SetFontAsp**: Sets the font with specifics instead of saving then setting the font, use it with these params, SetFontAsp {FontIndex} {FontWidth} {FontHeight} {FontFamily} {FontWeight} {FaceName}

- **ListSavedFont**: No Params, Just lists all your saved fonts.

- **RemoveSavedFont**: Removes a font from your save list, example to use it would be, RemoveSavedFont {Save Name For Font}




## Importing ⚡

`iwr -Uri "https://raw.githubusercontent.com/jh1sc/Powershell-SetFont/main/SetFont.psm1" -OutFile SetFont.psm1;ipmo .\SetFont.psm1;(Get-Command -Module SetFont).Name`
