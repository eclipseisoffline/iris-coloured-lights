// Coloured Lights: a library to add coloured lights to your Minecraft shader
// Copyright (C) 2024 https://github.com/systemneutron
// Coloured Lights is licensed under GNU GPLv3

#version 430 compatibility
#define VERTEX

#include /lib/cl/common.glsl

in vec3 at_midBlock;
in vec3 mc_Entity;

out fragment_data {
    vec2 textureCoord;
    vec2 lightMapCoord;
    vec4 glColor;

    vec3 worldPos;
    flat ivec3 localChunkPos;
} data;


void main() {
    gl_Position = ftransform();

    data.textureCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    data.lightMapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    data.glColor = gl_Color;

    data.worldPos = modelToWorldSpace(gl_Vertex.xyz);
    data.localChunkPos = blockPosToChunkPos(blockPosToLocalPos(worldPosToBlockPos(data.worldPos, at_midBlock)));
    lightCheck(at_midBlock, mc_Entity);
}
