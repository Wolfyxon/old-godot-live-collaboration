# Godot Live Collaboration
📡 Work on your Godot games with friends toghether!  
**Make sure to also see the [wiki](https://github.com/Wolfyxon/godot-live-collaboration/wiki) and articles such as [instalation](https://github.com/Wolfyxon/godot-live-collaboration/wiki/Instalation)**

## ⚠️ Warning ⚠️
The plugin is still at very early stage, there's no guarantee that your project will be saved correctly, it can even get permanentaly corrupted.
Using scripts, other users may also execute malicous code on each others' machines.  
__Always back up your work and work only with people you trust!__

## How does it work?
It's basic Godot multiplayer, but running in the editor itself.  
To check for changes, plugin saves properties of every node then repeatedly scans the project if the properties have changed.
If they do so, plugin sends a packet to all users to update that specific node. Of course, it's much more complicated speaking of code.


## Alternatives
This addon is still in development, it's limited and there's a risk of your project files getting corrupted. The best alternative is using [Git](https://git-scm.com/). You can learn merging branches from YouTube tutorials.
