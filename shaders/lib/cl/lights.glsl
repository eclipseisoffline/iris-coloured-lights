// Coloured Lights: a library to add coloured lights to your Minecraft shader
// Copyright (C) 2024 https://github.com/systemneutron
// Coloured Lights is licensed under GNU GPLv3

#ifndef COLOUR_LIGHTS_GLSL
#define COLOUR_LIGHTS_GLSL

struct ColouredLight {
    uint blockID;
    float blockLightLevel;
    vec3 lightColour;
    bool natural;
};

// Modify this array to add or remove coloured light blocks.
// Don't forget to update the array size
const ColouredLight[] colouredLights = ColouredLight[18](
    ColouredLight(89, 15, vec3(1.0, 0.43, 0.0), true), // Glowstone
    ColouredLight(91, 15, vec3(1.0, 0.54, 0.0), true), // Jack o lantern
    ColouredLight(138, 15, vec3(1.0, 1.0, 1.0), true), // Beacon
    ColouredLight(169, 15, vec3(0.0, 0.0, 1.0), true), // Sea lantern
    ColouredLight(213, 3, vec3(1.0, 0.49, 0.0), true), // Magma block
    ColouredLight(2511, 10, vec3(1.0, 0.35, 0.0), false), // Orange concrete
    ColouredLight(2513, 10, vec3(0.0, 0.0, 0.5), false), // Light blue concrete
    ColouredLight(2514, 10, vec3(1.0, 1.0, 0.0), false), // Yellow concrete
    ColouredLight(2515, 10, vec3(0.0, 0.5, 0.0), false), // Lime concrete
    ColouredLight(25110, 10, vec3(0.75, 0.0, 0.75), false), // Purple concrete
    ColouredLight(25114, 10, vec3(1.0, 0.0, 0.0), false), // Red concrete
    ColouredLight(463, 15, vec3(1.0, 0.54, 0.0), true), // Lantern
    ColouredLight(464, 15, vec3(1.0, 0.52, 0.0), true), // Campfire
    ColouredLight(485, 15, vec3(1.0, 0.33, 0.0), true), // Shroomlight
    ColouredLight(544, 10, vec3(0.6, 0.0, 1.0), true), // Crying obsidian
    ColouredLight(724, 15, vec3(1.0, 0.0, 1.0), true), // Pearlescent froglight
    ColouredLight(725, 15, vec3(0.0, 1.0, 0.0), true), // Verdant froglight
    ColouredLight(726, 15, vec3(1.0, 1.0, 0.0), true) // Ochre froglight
);

#endif
