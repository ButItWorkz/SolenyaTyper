## SolenyaTyper

A lightweight, native powershell utility designed to re-enable the basic OS's copy/paste feature via asynchronous hardware interrupt polling and raw keystroke simulation.
Built entirely using native .NET classes and Windows APIs, SolenyaTyper is a "Living off the Land" (LotL) tool that requires no third-party installations, compiled executables, or elevated privileges to execute.

## The Problem

Many web applications and enterprise forms utilize superficial security theater by attempting to ignore a user's clipboard paste attempts. This practice disrupts workflow, micromanages user interaction, and provides zero actual security benefit. Worse, it acts as an active security risk by preventing the use of modern security practices, such as pasting high-entropy credentials from Password Managers or dropping in MFA tokens.

SolenyaTyper re-enables this basic OS feature by reading the clipboard natively and injecting the contents into the active window as rapid-fire simulated keystrokes. To the target application, the input is indistinguishable from a user manually typing out the contents, ensuring your workflow remains uninterrupted.

## Features

Pure LoL Execution: Runs entirely in memory via powershell.exe.

Dynamic Hotkey Binding: Users can assign custom trigger keys and standard modifier combinations (Ctrl, Shift, Alt) at runtime.

Non-Blocking Architecture: Uses asynchronous state polling rather than heavy global keyboard hooks.

Edge-Detection Logic: Triggers on key release rather than key press to prevent hardware/software input collisions.

Transparent UI: Minimal, TopMost Windows Form overlay for active clipboard preview and state monitoring.

## Technical Mechanics

1. Hardware Polling over Global Hooks
Standard macro software often relies on SetWindowsHookEx to globally intercept keyboard input. This approach is heavy, prone to input latency, and risks crashing the UI thread if the hook isn't unhooked properly.

SolenyaTyper instead imports user32.dll to utilize GetAsyncKeyState(int vKey).

Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);' -Name 'NativeMethods' -Namespace 'User32'

A highly controlled background timer (System.Windows.Forms.Timer) polls the hardware state every 100ms. We use a bitwise AND operation against the 0x8000 mask to determine if the most significant bit is set (indicating the key is currently depressed physically).

## 2. State Management & Edge Detection

A common flaw in rudimentary keystroke simulators is race conditions. If a script triggers a simulated output while the user is still physically holding down the trigger keys (especially modifiers like Shift or Ctrl), the OS merges the physical and simulated inputs, resulting in chaotic native shortcuts executing instead of text.

SolenyaTyper utilizes a state management hashtable and edge-detection logic. It detects the moment the required hardware switches are closed (Arming), but waits for the switches to open (Release) before invoking the SendKeys class.

## 3. Regex Escape Routing

The System.Windows.Forms.SendKeys class interprets certain characters (+, ^, %, ~, (, ), {, }) as functional modifiers rather than strings. The script rips the clipboard contents and processes them through a Regex filter prior to injection, wrapping special characters in braces to guarantee pristine 1:1 data transfer.

## Usage

Save the script as SolenyaTyper.ps1. To execute the tool without a lingering PowerShell console window, launch it via the Run dialog (Win + R) or a shortcut using the following parameters:
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\SolenyaTyper.ps1"
Launch the script.

Click the dynamic binding box.

Press your desired hotkey or modifier combination (e.g., F2, Insert, Ctrl + Shift + V).

Copy text to your clipboard.

Focus the restricted input field.

Press and release your configured hotkey.

## Ethical Use & Liability Disclaimer

This utility is provided "as is" strictly for accessibility, workflow optimization, and educational demonstration of native operating system mechanics. It is designed to interact solely with the local system's clipboard and input simulation APIs. It is not intended to be utilized as a malicious keylogger, nor should it be used to bypass legitimate, authorized access controls or authentication mechanisms.

As the end-user, it is your absolute and sole responsibility to ensure that your usage of this tool is strictly ethical, legally compliant, and adheres to your organizational policies. Because this tool simulates raw, rapid-fire keystrokes, you are entirely responsible for the data you choose to process through it and the target applications you inject that data into.

The author assumes no liability and is not responsible for any misuse, damage, data leaks, account lockouts, or legal consequences resulting from the execution, modification, or deployment of this script.

## Disclaimer & EDR Considerations

For authorized, administrative, accessibility, and educational use only.
Note on Endpoint Detection: Because this script imports user32.dll, polls GetAsyncKeyState, and injects rapid keystrokes asynchronously, its mechanical profile is highly similar to rudimentary keyloggers or local C2 components. Heuristic-based Antivirus or EDR solutions may flag the execution. The script is provided un-obfuscated in native PowerShell specifically so all logic can be audited and verified prior to deployment or usage.

This is an open-source tool designed to showcase the ignorance of security theater and re-enable basic OS features. Enjoy!

## Development Transparency

This project was engineered with the assistance of an AI Large Language Model (LLM). The AI was utilized as a pair-programming tool to assist with Windows API integration (user32.dll), asynchronous hardware polling logic, and WinForms UI scaffolding. The architectural vision, "Living off the Land" operational constraints, and final code validation remain strictly human-driven.

## Licensing

MIT License

Copyright (c) 2026 ButItWorkz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
