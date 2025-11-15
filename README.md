For Paracortical Initiative, 2025, Diogo "Theklo" Duarte

Other projects:
https://bsky.app/profile/diogo-duarte.bsky.social
https://diogo-duarte.itch.io/
https://github.com/Theklo-Teal


# DESCRIPTION
A toy emulator for retro style CPUs, for example the Motorola 6809. Made in Godot.
This is part of my collection of projects in indefinite hiatus. I release it publicly in case someone likes the ideas and wants to develop them further or volunteers to work with me on them.
See "WHY IN HIATUS?" for more information.

# THE CONCEPT
This is a very ISA agnostic CPU, but which you can configure the various commands with names of recognized CPUs so the assembly code looks reminiscent.
The point is to be an environment where you write assembly code and see the results on a representation of the RAM.
The more interesting thing is to invent your own instruction set and see how things behave. This can be done by creating a script in the "Architectures/" folder.
Potentially the application could also simulate various peripherals like displays and teletype. But it isn't meant to be efficient as an emulator.

# INSTALLATION
Put these files in your Godot projects folder and search for it in project manager of Godot! Compatible with Godot 4.5.

# USAGE
To create an architecture, you have to create a subfolder in "Architectures/" and inside it needs a "core.gd" script which extends "CpuCore". Here you define the flags and registers. You also write the behaviour for each update tick, like fetching instructions or calling functions pertinent to an opcode.
You should add the behaviour of each opcode as a different function.
You can list all the opcodes and mnemonics in "microcode.cfg".
"documentation.cfg" is also recommended. In there you can give a description of the ISA/CPU and some instructions on the opcodes and mnemonics on how to write assembly.

# WHY IN HIATUS?
Altough steps were taken to sucessfully increase the update tick rate of the simulation, this emulator will always be limited to very slow emulation.
Maybe someone knows how to harness the power of multiple threads and parallel processes to fix this, but that isn't me.
What bothers me most about the current iteration is how frustrating it is to make custom UI have correct positioning and take up space around other UI.
Godot doesn't document very well how to make custom UI to look and behave seamless with native ones.
Other issue I'm not sure how hard it is to solve, is how to translate shortened mnemonics in assembly to the full named ones, which properly translate to opcodes. There's a rudimentary mechanism for this, relying on the arguments to decide between opcodes, but it isn't versatile. Decoding pseudo-instructions is also a related problem.
