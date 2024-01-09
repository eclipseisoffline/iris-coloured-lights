// Coloured Lights: a library to add coloured lights to your Minecraft shader
// Copyright (C) 2024 https://github.com/systemneutron
// Coloured Lights is licensed under GNU GPLv3

#version 430 core
#include /lib/cl/common.glsl

uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform float alphaTestRef;

in fragment_data {
    vec2 textureCoord;
    vec2 lightMapCoord;
    vec4 glColor;

    vec3 worldPos;
    flat ivec3 localChunkPos;
} data;

layout(location = 0) out vec4 colortex0;

void main() {
    colortex0 = texture(gtexture, data.textureCoord) * data.glColor;

    if (colortex0.a < alphaTestRef) {
        discard;
    }

    vec4 startLight = texture(lightmap, data.lightMapCoord);
    colortex0 = applyColouredLight(colortex0, startLight, data.worldPos, data.localChunkPos);
}
