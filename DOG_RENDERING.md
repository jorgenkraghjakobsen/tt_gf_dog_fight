# Procedural Dog Rendering

This document describes the procedural dog rendering system implemented in `dogbattle_top_v8.v`.

## Overview

Instead of using bitmaps or simple filled rectangles, each dog is rendered procedurally using mathematical conditions. This approach is hardware-efficient and creates recognizable dog shapes with multiple features.

## Dog Structure

Each dog (48x32 pixels) is composed of:

### 1. **Body** (Main Rectangle)
- Position: x: 12-40, y: 8-24
- The main torso/body of the dog
- Colored with the dog's primary color

### 2. **Head** (Circle)
- Center: (40, 16) relative to dog position
- Radius: ~8 pixels (radius² = 64)
- Positioned at the front (right side) of the dog
- Uses circular math: `dx² + dy² < 64`

### 3. **Ears** (Two Triangles)
- Left ear: x: 36-40, y: 8-14 (triangular)
- Right ear: x: 40-44, y: 8-14 (triangular)
- Positioned on top of the head
- Adds character and makes the shape more dog-like

### 4. **Eyes** (Small Dots)
- Position: x: 41-43, y: 13-15
- Always rendered in black for contrast
- Single eye visible (side profile view)

### 5. **Legs** (Four Rectangles)
- Front left: x: 32-36, y: 24-30
- Front right: x: 38-42, y: 24-30
- Back left: x: 14-18, y: 24-30
- Back right: x: 20-24, y: 24-30
- Extend below the body

### 6. **Tail** (Curved Shape)
- Position: x: 4-12, y: 6-14
- Curved/tapered using: `(x-4) + (y-6) < 10`
- Positioned at the back (left side)
- Adds dynamic appearance

## Rendering Function

```verilog
function [2:0] render_dog;
    input [9:0] pxi;  // pixel x coordinate
    input [8:0] pyi;  // pixel y coordinate
    input [9:0] bx;   // dog's bounding box x
    input [8:0] by;   // dog's bounding box y
```

### Return Value (3 bits)
- Bit [2]: `is_dog_pixel` - Is this pixel part of the dog?
- Bit [1]: `is_outline` - Is this an outline/edge pixel?
- Bit [0]: `is_eye` - Is this an eye pixel?

## Color Rendering

The rendering uses three color modes:

1. **Eyes** (is_eye = 1)
   - Always black (RGB = 000)
   - Provides contrast and detail

2. **Outline** (is_outline = 1)
   - Darker version of main color
   - Created by shifting color bits: `{1'b0, col[2], col[1]}`
   - Gives the dog definition

3. **Main Color** (default)
   - Dog's assigned color from `color_idx`
   - Expanded from 3-bit to full RGB output

## Dog Orientation

Currently, all dogs face **right** (positive X direction):
- Head on the right side (x: 36-48)
- Tail on the left side (x: 4-12)
- Legs underneath (y: 24-30)

## Hardware Efficiency

This procedural approach is efficient because:
- **No memory** needed for bitmap storage
- **Combinational logic** only - simple comparisons and math
- **Reusable** - same function renders all dogs
- **Scalable** - easy to add features or modify shape

## Comparison to Simple Box

| Aspect | Old (Filled Box) | New (Procedural Dog) |
|--------|------------------|----------------------|
| Logic | ~10 comparisons | ~40 comparisons |
| Memory | 0 bits | 0 bits |
| Appearance | Solid rectangle | Dog-shaped with features |
| Colors | 1 solid color | 3 color modes (main, outline, eyes) |

## Future Enhancements

Possible improvements:
1. **Direction-based rendering** - Flip dog based on velocity direction
2. **Animation frames** - Different leg positions for running
3. **Expression changes** - Based on hits or state
4. **Size variation** - Different dog sizes based on power_state
5. **Accessories** - Collars, spots, or other features per dog

## Technical Notes

- The function is called for every pixel within each dog's bounding box
- Results are pre-calculated as wires (`dog0_render`, etc.) for efficiency
- Relative coordinates simplify the math: `rel_x = px - bx`, `rel_y = py - by`
- All dogs share the same shape but can have different colors
