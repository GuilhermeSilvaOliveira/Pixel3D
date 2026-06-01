# Pixel3D
A tool designed to create pixel art effects in 3D scenes in Unity. It has a simple and versatile design, is ready to use, and is easy to modify.

## Features

- Supports any type of resolution.
- Camera Pixel Snap (Pixel Perfect).
- Object Pixel Snap for moving objects.  

## How Work
Pixel3D works in two parts. To generate the pixelated screen effect, a low-scale rendering method is used along with a pixelSnap(pixelPerfect) function made for the camera to avoid the jitter problem.
The second part is for objects that need to move, a shader was developed using a pixelSnap 3D method directly on the object's vertices to avoid the same jitter problem.

- <strong>PixelSnap(Object)</strong>

<img src='https://media3.giphy.com/media/v1.Y2lkPTc5MGI3NjExdzR2eGttbXd5aHd1MWV4YjJ4aTJwb21hYXlvZXRhNnd1enBwbHFqcyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/jHra5Aj93jbEm0RpW6/giphy.gif'></img>

- <strong>Cam pixelSnap(PixelPerfect)</strong>

<img width="750" height="422" alt="Image" src="https://github.com/user-attachments/assets/a21c91bb-0fad-4090-b729-4070348d7105" />

- <p><strong>Why use one snap on the camera and another on objects?</strong> Because they are distinct things, one does not affect the other. If the camera has PixelSnap(PixelPerfect) and moves, the visual is perfect.
  If the objects are immobile, if they move independently of the camera and do not have any type of snap, visual errors will occur since the camera is attached to the grid and the object to another, therefore the use of two snaps is necessary, the opposite is also valid.</p>

## Bugs and limitations
It has not yet been possible to create a version for ShaderGraph of the PixelSnap shader.
