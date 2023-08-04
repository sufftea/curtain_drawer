#version 460 core

#include <flutter/runtime_effect.glsl>

#define PI 3.1415926535

precision mediump float;

uniform vec2 resolution;
uniform float progress; // 1: closed; 0: opened
uniform float impactPoint; // 0: highest; 1: lowest
uniform sampler2D tex;

out vec4 fragColor;

vec4 compute() {
  vec2 st = FlutterFragCoord().xy / resolution.xy;



  st.x += pow(2, -pow((st.y - impactPoint) * 3, 2)) * progress * st.x * 1.5;
    // + progress * st.x;
  st.y += sin(pow(st.x, 1.5) * PI * 10) * progress * 0.005;
  float tint = cos(pow(st.x, 1.5) * PI * 10) * progress;
  
  if (st.x > 1) {
    return vec4(0, 0, 0, 0);
  }

  vec4 col = texture(
    tex, 
    st
  );
  
  return mix(col, vec4(0, 0, 0, 1), tint * 0.2);
}

void main() {
  fragColor = compute();
}