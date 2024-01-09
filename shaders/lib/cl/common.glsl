// Coloured Lights: a library to add coloured lights to your Minecraft shader
// Copyright (C) 2024 https://github.com/systemneutron
// Coloured Lights is licensed under GNU GPLv3

#ifndef COLOUR_COMMON_GLSL
#define COLOUR_COMMON_GLSL

#include /lib/cl/lights.glsl

// Options
// Don't change the ranges unless you know what you're doing
#define COLOURED_LIGHTS_RENDER_DISTANCE 16 // [2 4 6 8 10 12 14 16]
#define COLOURED_LIGHTS_RENDER_DISTANCE_VERTICAL 16 // [2 4 6 8 10 12 14 16]
#define MAX_COLOURED_LIGHTS 64 // [8 16 24 32 40 48 56 64]
#define COLOUR_INTENSITY 1.0 // [0.0 0.33 0.66 1.0 1.5 2.0 4.0]
#define BLOCK_LIGHTS

struct LightColourBlock {
    ivec3 blockPos;
    uint lightID;
};

// Don't change unless you know what you're doing
const uint maxChunks = COLOURED_LIGHTS_RENDER_DISTANCE;
const uint maxVerticalChunks = COLOURED_LIGHTS_RENDER_DISTANCE_VERTICAL;
const uint localBlockOffset = (maxChunks / 2) * 16;
const uint localBlockVerticalOffset = (maxVerticalChunks / 2) * 16;

const uint maxColouredLightsChunk = MAX_COLOURED_LIGHTS;

const vec3 centreOffset = vec3(0.5);
const float midblockUnit = 64.0;

// Buffer size = maxChunks * maxVerticalChunks * maxChunks * 512
layout (std430, binding = 0) coherent buffer positionsCheckedBuffer {
    uint[] positionsChecked;
};

// Buffer size = maxChunks * maxVerticalChunks * maxChunks * 4 + maxChunks * maxVerticalChunks * maxChunks * maxColouredLightsChunk * 16
layout(std430, binding = 1) coherent buffer lightColoursBuffer {
    uint[maxChunks][maxVerticalChunks][maxChunks] sizes;
    LightColourBlock[][maxColouredLightsChunk] lights;
} lightColours;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform vec3 cameraPosition;

ivec3 worldPosToBlockPos(vec3 worldPos, vec3 midBlock) {
    worldPos += (midBlock / midblockUnit);
    worldPos = floor(worldPos);
    return ivec3(worldPos);
}

ivec3 blockPosToChunkPos(ivec3 blockPos) {
    return ivec3(floor(blockPos / 16.0));
}

ivec3 blockPosToLocalPos(ivec3 blockPos) {
    int cameraX = int(floor(cameraPosition.x));
    int cameraY = int(floor(cameraPosition.y));
    int cameraZ = int(floor(cameraPosition.z));
    return ivec3(int((blockPos.x - cameraX) + localBlockOffset),
                 int((blockPos.y - cameraY) + localBlockVerticalOffset),
                 int((blockPos.z - cameraZ) + localBlockOffset));
}

bool localChunkPosOutOfBounds(ivec3 localChunkPos) {
    return (localChunkPos.x < 0 || localChunkPos.y < 0 || localChunkPos.z < 0
        || localChunkPos.x >= maxChunks || localChunkPos.y >= maxVerticalChunks || localChunkPos.z >= maxChunks);
}

bool posMarked(ivec3 localBlockPos) {
    ivec3 localChunkPos = blockPosToChunkPos(localBlockPos);
    if (localChunkPosOutOfBounds(localChunkPos)) {
        return true;
    }

    /* positionsChecked layout:
      Dimensions: maxChunks * maxVerticalChunks * maxChunks * 128, mapped to a 1D array because of GLSL
      Every chunk consists of 128 sectors, every sector is represented by one uint and stores 32 blocks (one bit per block)
      Every Y level of the chunk consists of 8 sectors. One sector is 16 blocks over the X axis and 2 over the Z axis
    */
    uint sector = uint(((localBlockPos.y % 16) * 8) + ((localBlockPos.z % 16) / 2));
    uint positionsCheckedIndex = ((localChunkPos.x * maxVerticalChunks + localChunkPos.y) * maxChunks + localChunkPos.z) * 128 + sector;
    if (positionsCheckedIndex >= positionsChecked.length()) {
        return true;
    }
    uint bit = uint(localBlockPos.x % 16 + ((localBlockPos.z % 16) % 2) * 16);
    uint bitmask = 1 << bit;
    if ((positionsChecked[positionsCheckedIndex] | bitmask) == positionsChecked[positionsCheckedIndex]) {
        return true;
    }
    uint original = atomicOr(positionsChecked[positionsCheckedIndex], bitmask);
    return ((original | bitmask) == original);
}

vec4 applyColouredLight(vec4 startColour, vec4 startLight, vec3 worldPos, ivec3 localChunkPos) {
    if (localChunkPosOutOfBounds(localChunkPos)) {
        startColour *= startLight;
        return startColour;
    }

    vec3 colours;
    float colourCount = 0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                ivec3 chunk = localChunkPos + ivec3(x, y, z);
                if (localChunkPosOutOfBounds(chunk)) {
                    continue;
                }

                uint size = lightColours.sizes[chunk.x][chunk.y][chunk.z];
                uint chunkIndex = chunk.x + maxChunks * (chunk.y + maxVerticalChunks * chunk.z);
                for (int i = 0; i < size; i++) {
                    LightColourBlock lightBlock = lightColours.lights[chunkIndex][i];

                    vec3 lightColourPos = lightBlock.blockPos + centreOffset;
                    ColouredLight light = colouredLights[lightBlock.lightID];

                    float d = abs(lightColourPos.x - worldPos.x) + abs(lightColourPos.y - worldPos.y) + abs(lightColourPos.z - worldPos.z);
                    if (d < light.blockLightLevel) {
                        float weight = ((light.blockLightLevel - d) / light.blockLightLevel) * COLOUR_INTENSITY;
                        vec3 colour = light.lightColour * weight * weight;
                        colours += colour;
                        colourCount += weight;

                        if (!light.natural) {
                            startLight = max(startLight, weight);
                        }
                    }
                }
            }
        }
    }

    startColour *= startLight;
    if (colourCount > 0) {
        vec3 averageColour = colours / colourCount;
        startColour += startColour * vec4(averageColour, 0.0);
    }

    return startColour;
}

#ifdef VERTEX
vec3 modelToWorldSpace(vec3 modelPos) {
    vec3 viewPos = (gl_ModelViewMatrix * vec4(modelPos, 1.0)).xyz;
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    return feetPlayerPos + cameraPosition;
}

vec4 worldToClipSpace(vec3 worldPos) {
    vec3 feetPlayerPos = worldPos - cameraPosition;
    vec3 viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;
    return gbufferProjection * vec4(viewPos, 1.0);
}

void registerPos(ivec3 blockPos, uint id) {
    ivec3 localBlockPos = blockPosToLocalPos(blockPos);
    ivec3 localChunkPos = blockPosToChunkPos(localBlockPos);

    // Also runs out of bounds check
    if (posMarked(localBlockPos)) {
        return;
    }

    if (lightColours.sizes[localChunkPos.x][localChunkPos.y][localChunkPos.z] >= maxColouredLightsChunk) {
        return;
    }

    uint localIndex = atomicAdd(lightColours.sizes[localChunkPos.x][localChunkPos.y][localChunkPos.z], 1);
    // Check twice because of concurrency
    if (localIndex >= maxColouredLightsChunk) {
        return;
    }
    uint chunkIndex = localChunkPos.x + maxChunks * (localChunkPos.y + maxVerticalChunks * localChunkPos.z);
    lightColours.lights[chunkIndex][localIndex].blockPos = blockPos;
    lightColours.lights[chunkIndex][localIndex].lightID = id;
}

void lightCheck(vec3 midBlock, vec3 mcEntity) {
    vec3 worldPos = modelToWorldSpace(gl_Vertex.xyz);
    ivec3 blockPos = worldPosToBlockPos(worldPos, midBlock);

    uint blockID = uint(round(mcEntity.x));
    for (int i = 0; i < colouredLights.length(); i++) {
        #ifndef BLOCK_LIGHTS
        if (!colouredLights[i].natural) {
            continue;
        }
        #endif
        if (colouredLights[i].blockID == blockID) {
            registerPos(blockPos, i);
            break;
        }
    }
}
#endif

#endif
