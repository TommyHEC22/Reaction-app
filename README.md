# reaction_game

Reaction Game is a mobile app made to train the users focus, reactions, predictive thinking and more through multiple small mini games.

## Why I built it

I built this as I wanted a NeuroTracker-style multi-object tracking test for my training and couldn't find any for free that were reasonable. So made my own, I also couldn't find an app with predictive style games to enhance predictive thinking. I also did this as an attempt to learn flutter/dart for app development.

## What it does

Reaction game is very simple, it has a homepage fitted out with 4 mini games all aimed at training slightly different things.

## How it works

1. Screen color change:
   The screen goes red with a "wait for green" text while it waits for a random period of time between 2 and 10 seconds. as soon as the screen goes green a clock starts that times how long it takes the user to press the screen recording their reaction time. If the users presses to early, the round cancels and they get a "too early".

2. Random Dot:
   This game is very similar to screen color change, the difference is that you have to press a specific 80 pixel circle on the screen not just anywhere. The position is stored as a fraction of the screen (0 to 1) and converted to pixels at draw time, so it works on any screen size. Hitting the dot records your time. Tapping empty space while it's showing counts as "Missed"

3. Dot tracker:
   Balls are placed randomly on the screen with an overlap check so none start onto of each other. A certain number of balls depending on the level then show as red for 2 seconds for the user to know which ones to track. They all then turn grey and move at varying speed depending on the level for 6 seconds with the balls bouncing off the walls and also each other. The user then taps the ones they think were the targets. If they pass the round the difficulty increases (more balls, more targets, higher speeds) and if they fail it moves down.

4. Anticipation path:
   Builds a random path from waypoints with corner rounded off with curves. Level 1 is a straight line and each level adds a corner. A ball then travels along the path at a constant speed. For the last part of the path (31% at level 1 and rising to 67% at level 5) the ball goes invisible so the user had to tap the screen at the exact time they think the ball should reach the end. The game tells you how many milliseconds early or late you were, shows where the ball actually was, and rates you: perfect under 40 ms, great under 100, good under 200

## Problems hit

The first issue that I faced was the balls stopping behind mobile devices front camera notch etc as it used the edges of the screen as the walls to bounce off on the dot tracker. To fix this, I created an invisible box to sit inside the middle part of the screen for the balls to bounce in so they don't get stuck behind anything.

There was a similar issue in the anticipation path game where the line would go behind the level selector. This was fixed in the same way as the dot tracker.

The anticipation path game would never end if the screen wasn't pressed. The game simply ended 1.6* after the ball should've arrived as a stop to this.

## Tech

- Flutter
- Dart
- Ticker
- Timer
- Stopwatch
- CustomPainter
- flutter_launcher_icons



   
