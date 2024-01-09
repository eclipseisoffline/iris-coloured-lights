// Coloured Lights: a library to add coloured lights to your Minecraft shader
// Copyright (C) 2024 https://github.com/systemneutron
// Coloured Lights is licensed under GNU GPLv3

#version 430 core
#include /lib/cl/common.glsl

const ivec3 workGroups = ivec3(524288, 1, 1);

layout (local_size_x = 1, local_size_y = 1) in;

void main() {
    uint id = gl_WorkGroupID.x;

    if (id < positionsChecked.length()) {
        positionsChecked[id] = 0;
    }
    if (id < maxChunks * maxVerticalChunks * maxChunks) {
        uint z = id / (maxChunks * maxVerticalChunks);
        uint y = (id / maxChunks) % maxVerticalChunks;
        uint x = id % maxChunks;
        lightColours.sizes[x][y][z] = 0;
    }
}
