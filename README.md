# Coloured Lights - Minecraft Iris shader library

Coloured Lights is a library to easily add coloured light blocks to your Minecraft Iris shader. SSBOs are a required feature. Can also be used standalone.

## License

All the code in this repository is licensed under GNU GPLv3.

## Usage

### Using standalone

Download a ZIP file of this repository on GitHub, then copy the ZIP file over to your shaderpacks directory. Everything should work out of the box.

### Including in your own shaderpack

All shaders using the library must be using GLSL 430 or above.
Copy the `lib` folder in the `shaders` directory to your own `shaders` directory. In your `gbuffers_terrain` vertex shader, add the following lines at the top, below your `#version` statement:

```glsl
#define VERTEX

#include /lib/cl/common.glsl
```

Your vertex shader must be using the compatibility profile of GLSL. In your main function, add the following line:
```glsl
lightCheck(at_midBlock, mc_Entity);  
```

`at_midBlock` and `mc_Entity` being input attributes.

In every fragment shader where you will want to apply the coloured lights, add the following line below your `#version` statement:

```glsl
#include /lib/cl/common.glsl  
```

Your fragment shader can use the core profile of modern GLSL versions. In the main function, add the following lines:

```glsl
vec4 startLight = texture(lightmap, data.lightMapCoord);
colortex0 = applyColouredLight(colortex0, startLight, worldPos, localChunkPos);
```

`colortex0` is your output colour. It's important that you don't multiply your output colour with the lightmap texture value, the `applyColouredLight` method will do that for you.

`worldPos` is a `vec3` and `localChunkPos` is a `flat ivec3`, both passed from the vertex shader, and can be calculated like this:

```glsl
worldPos = modelToWorldSpace(gl_Vertex.xyz);
localChunkPos = blockPosToChunkPos(blockPosToLocalPos(worldPosToBlockPos(worldPos, at_midBlock)));
```

`at_midBlock` being an input attributes.

Copy the `begin.csh` file in the `shaders` directory over to your `shaders` directory.

The library contains some default block light colours, but you'll have to include the block IDs. Merge the `block.properties` file in the `shaders` directory with your own `block.properties` file.

You'll also have to correctly set up your SSBOs. To do this, merge the `shaders.properties` file in the `shaders` directory with your own `shaders.properties` file. This will also include a nice option screen for the coloured lights. Copy the `lang` directory over to your `shaders` directory for English translation keys of the option screen.

#### Adding/changing the coloured light blocks

Open the `/lib/cl/lights.glsl` file in your `shaders` directory. This should contain the  `colouredLights` array, which contains all the coloured light blocks. The syntax is as follows:

```glsl
const ColouredLight[] colouredLights = ColouredLight[<array size>](
    ColouredLight(<block ID>, <light level>, <light colour>, <natural>),
    ...
);
```

- `<array size>` is the size of the `colouredLights` array.
- `<block ID>` is an unsigned integer, the ID of the coloured light block as defined in `block.properties`.
- `<light level>` is the light level the block gives (can be a float, but is recommended to be an integer).
- `<light colour>` is a `vec3`, the colour the block gives off.
- `<natural>` is a boolean. Only set it to `false` if the block in question doesn't give light in vanilla.

## Known issues

- Light colours render through blocks due to occlusion culling issues.
- Light colours can glitch out in the Nether (and possibly End).
