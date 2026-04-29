# SolenyaTyper
A lightweight, native powershell utility designed to bypass client-side paste restrictions (such as JavaScript onpaste blocks) via asynchronous hardware interrupt polling and raw keystroke simulation.
Built entirely using native .NET classes and Windows APIs, SolenyaTyper is a "Living off the Land" (LoL) tool that requires no third-party installations, compiled executables, or elevated privileges to execute.

# The Problem
Many web applications and enterprise forms implement superficial security theater by blocking clipboard pasting. This practice disrupts workflow, micromanages user interaction, and provides zero actual security benefits.

SolenyaTyper circumvents these browser-level restrictions by reading the clipboard natively and injecting the contents into the active window as rapid-fire simulated keystrokes. To the target application, the input is indistinguishable from a user typing extremely fast.

# Features
Pure LoL Execution: Runs entirely in memory via powershell.exe.

Dynamic Hotkey Binding: Users can assign custom trigger keys and standard modifier combinations (Ctrl, Shift, Alt) at runtime.

Non-Blocking Architecture: Uses asynchronous state polling rather than heavy global keyboard hooks.

Edge-Detection Logic: Triggers on key release rather than key press to prevent hardware/software input collisions.

Transparent UI: Minimal, TopMost Windows Form overlay for active clipboard preview and state monitoring.

# Technical Mechanics
1. Hardware Polling over Global Hooks
Standard macro software often relies on SetWindowsHookEx to globally intercept keyboard input. This approach is heavy, prone to input latency, and risks crashing the UI thread if the hook isn't unhooked properly.

SolenyaTyper instead imports user32.dll to utilize GetAsyncKeyState(int vKey).

Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);' -Name 'NativeMethods' -Namespace 'User32'

A highly controlled background timer (System.Windows.Forms.Timer) polls the hardware state every 100ms. We use a bitwise AND operation against the 0x8000 mask to determine if the most significant bit is set (indicating the key is currently depressed physically).

# 2. State Management & Edge Detection
A common flaw in rudimentary keystroke simulators is race conditions. If a script triggers a simulated output while the user is still physically holding down the trigger keys (especially modifiers like Shift or Ctrl), the OS merges the physical and simulated inputs, resulting in chaotic native shortcuts executing instead of text.

SolenyaTyper utilizes a state management hashtable and edge-detection logic. It detects the moment the required hardware switches are closed (Arming), but waits for the switches to open (Release) before invoking the SendKeys class.

# 3. Regex Escape Routing
The System.Windows.Forms.SendKeys class interprets certain characters (+, ^, %, ~, (, ), {, }) as functional modifiers rather than strings. The script rips the clipboard contents and processes them through a Regex filter prior to injection, wrapping special characters in braces to guarantee pristine 1:1 data transfer.

# Usage
Save the script as SolenyaTyper.ps1. To execute the tool without a lingering PowerShell console window, launch it via the Run dialog (Win + R) or a shortcut using the following parameters:
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Path\To\SolenyaTyper.ps1"
Launch the script.

Click the dynamic binding box.

Press your desired hotkey or modifier combination (e.g., F2, Insert, Ctrl + Shift + V).

Copy text to your clipboard.

Focus the restricted input field.

Press and release your configured hotkey.

# Disclaimer & EDR Considerations
For administrative, accessibility, and educational use. Note on Endpoint Detection: Because this script imports user32.dll, polls GetAsyncKeyState, and injects rapid keystrokes asynchronously, its mechanical profile is highly similar to rudimentary keyloggers or local C2 components. Heuristic-based Antivirus or EDR solutions may flag the execution. The script is provided un-obfuscated in native PowerShell specifically so all logic can be audited and verified prior to deployment or usage. 
There's no "Trust me bro" here, just an open source tool to bypass ignorant security theater, enjoy!

# Licensing
There is none, software should be free!
