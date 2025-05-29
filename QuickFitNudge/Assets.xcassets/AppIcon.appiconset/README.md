# App Icon Placeholder

This directory contains the app icon configuration for QuickFit Nudge.

## Required Assets

The app icon should be created as a **1024x1024 PNG** file named `app-icon-1024.png` and placed in this directory.

## Design Guidelines

### Theme
- **Primary Colors**: Fitness/wellness inspired gradient (blues, teals, energetic colors)
- **Icon Element**: Subtle fitness symbol (dumbbell, activity rings, or abstract movement)
- **Style**: Modern, clean, approachable

### Technical Requirements
- **Format**: PNG with transparency support
- **Size**: 1024x1024 pixels (App Store requirement)
- **Corner Radius**: Let iOS handle rounded corners automatically
- **No Text**: Avoid text in the icon as it becomes unreadable at small sizes

### Design Concepts
1. **Minimalist Dumbbell**: Simple geometric dumbbell shape on gradient background
2. **Activity Symbol**: Circular progress rings suggesting movement/progress
3. **Abstract Motion**: Dynamic shapes suggesting quick, efficient movement
4. **Time + Fitness**: Clock element combined with fitness symbol

## Implementation
Once you have the 1024x1024 icon:

1. Add `app-icon-1024.png` to this directory
2. Update `Contents.json` to reference the file:
   ```json
   {
     "filename": "app-icon-1024.png",
     "idiom": "universal",
     "platform": "ios", 
     "size": "1024x1024"
   }
   ```
3. Xcode will automatically generate other required sizes

## Current Status
⚠️ **Placeholder only** - Replace with actual app icon before App Store submission

## Tools for Creation
- **Figma/Sketch**: Vector design tools
- **Adobe Illustrator**: Professional vector graphics
- **Icon generators**: Online tools for iOS app icons
- **SF Symbols**: Apple's system icons for inspiration (but create original)