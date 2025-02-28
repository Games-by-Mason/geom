# Geom

Geometry for game development.

# Status

I'm going to be fleshing this out into a more cohesive library as I require more functionality.

Currently, it's still missing basic functionality--many 3D types, projection matrices, etc.

# "For Game Development"?

This library has features you wouldn't expect out of a linear algebra library, and lacks features you would.

Furthermore, it prioritizes speed over both precision and determinism across CPUs. You shouldn't use this library for scientific computing, or for something like rollback netcode. You *should* use it when you wanna go fast.

This library runs *much* faster in release mode. It's recommended that you build it in release mode even when the rest of your app is in debug mode.
